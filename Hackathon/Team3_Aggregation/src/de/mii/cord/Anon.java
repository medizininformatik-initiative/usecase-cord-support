/**
 * CORD Anonymization Pipeline
 * Copyright (C) 2021 - CORD
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package de.mii.cord;

import java.io.IOException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;

import org.deidentifier.arx.ARXAnonymizer;
import org.deidentifier.arx.ARXConfiguration;
import org.deidentifier.arx.AttributeType;
import org.deidentifier.arx.AttributeType.Hierarchy;
import org.deidentifier.arx.Data;
import org.deidentifier.arx.DataHandle;
import org.deidentifier.arx.criteria.PrivacyCriterion;

/**
 * First class of aggregates
 * @author Fabian Prasser
 */
public class Anon {

	/**
	 * Selection of an attribute
	 * @author Fabian Prasser
	 */
	public static class Selection {
		
		/** Attribute */
		public final String attribute;

		/**
		 * Create a new instance
		 * @param attribute
		 */
		public Selection(String attribute) {
			this.attribute = attribute;
		}
	}

	/**
	 * Generalization of an attribute
	 * @author Fabian Prasser
	 */
	public static class Generalization {
		
		/** Attribute */
		public final String attribute;
		
		/** Hierarchy */
		public final Hierarchy hierarchy;
		
		/** Level */
		public final int level;

		/**
		 * Create a new instance
		 * @param attribute
		 * @param hierarchy
		 * @param level
		 */
		public Generalization(String attribute, Hierarchy hierarchy, int level) {
			this.attribute = attribute;
			this.hierarchy = hierarchy;
			this.level = level;
		}
	}
	
	/**
	 * Anonymization
	 * @param data
	 * @param selection
	 * @param generalization
	 * @param model
	 * @return
	 * @throws IOException 
	 */
	public static Data anonymize(Data data, List<Selection> selection, List<Generalization> generalization, PrivacyCriterion model) throws IOException {
		
		/* Clone*/
		Data input = Util.getData(data.getHandle());
		
		/* Configure attributes*/
		for (int i = 0; i < input.getHandle().getNumColumns(); i++) {
			input.getDefinition().setAttributeType(input.getHandle().getAttributeName(i),
					AttributeType.IDENTIFYING_ATTRIBUTE);
		}
		for (Selection s : selection) {
			input.getDefinition().setAttributeType(s.attribute, AttributeType.INSENSITIVE_ATTRIBUTE);
		}
		for (Generalization g : generalization) {
			if (g.hierarchy == null) {
				input.getDefinition().setAttributeType(g.attribute, AttributeType.QUASI_IDENTIFYING_ATTRIBUTE);
			} else {
				input.getDefinition().setAttributeType(g.attribute, g.hierarchy);
				input.getDefinition().setMinimumGeneralization(g.attribute, g.level);
				input.getDefinition().setMaximumGeneralization(g.attribute, g.level);
			}
		}
		
		/* Configure privacy */
		ARXConfiguration config = ARXConfiguration.create();
		config.setSuppressionLimit(1.0d);
		config.addPrivacyModel(model);
		
		/* Anonymize*/
		DataHandle output = new ARXAnonymizer().anonymize(input, config).getOutput();
		
		int removed = output.getStatistics().getEquivalenceClassStatistics().getNumberOfSuppressedRecords();
		int total = output.getStatistics().getEquivalenceClassStatistics().getNumberOfRecordsIncludingSuppressedRecords();
		System.out.println(" - Number of records removed: " + removed + "/" + total);
		
		/* Aggregate*/
		return count(output, selection, generalization);
	}

	/**
	 * Distinct + count
	 * @param output
	 * @param selection
	 * @param generalization
	 * @return
	 */
	private static Data count(DataHandle output, List<Selection> selection, List<Generalization> generalization) {
		
		/* Map*/
		Map<List<String>, Integer> aggregation = new HashMap<>();
		/* Result */
		List<String[]> result = new ArrayList<>();
		/* Attributes*/
		List<String> attributes = new ArrayList<>();
		
		// Collect attributes
		for (Selection s : selection) {
			attributes.add(s.attribute);
		}
		for (Generalization g : generalization) {
			attributes.add(g.attribute);
		}
		
		/* Add rows*/
		for (int row = 0; row < output.getNumRows(); row++) {
			
			// Only non-suppressed rows
			if (!output.isSuppressed(row)) {
				
				// Construct row
				List<String> line = new ArrayList<>();
				for (String name : attributes) {
					int column = output.getColumnIndexOf(name);
					line.add(output.getValue(row, column));
				}
				
				// Count line
				if (!aggregation.containsKey(line)) {
					aggregation.put(line, 1);
				} else {
					aggregation.put(line, ((Integer)aggregation.get(line)) + 1);
				}
			}
		}
		
		/* Construct header*/
		List<String> header = new ArrayList<String>();
		header.addAll(attributes);
		header.add(IO.FIELD_COUNT);
		result.add(header.toArray(new String[header.size()]));
		
		/* Add data*/
		for (Entry<List<String>, Integer> entry : aggregation.entrySet()) {
			int count = entry.getValue();
			// int lower = count / 5;
			// int upper = count + 5;
			List<String> row = entry.getKey();
			row.add(String.valueOf(count));
			result.add(row.toArray(new String[row.size()]));
		}
		
		/* Done*/
		return Data.create(result);
	}
}