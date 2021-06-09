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

import java.io.File;
import java.io.IOException;
import java.nio.charset.Charset;
import java.text.ParseException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

import org.deidentifier.arx.AttributeType.Hierarchy;
import org.deidentifier.arx.Data;
import org.deidentifier.arx.DataHandle;
import org.deidentifier.arx.DataSource;
import org.deidentifier.arx.DataType;
import org.deidentifier.arx.io.CSVDataOutput;

/**
 * Data loading
 * @author Fabian Prasser
 */
public class IO {
	
	/** Charset*/
	public static final Charset CHARSET = Charset.defaultCharset();

	/** Not available */
	public static final String VALUE_NA = "n/a";
	/** Not available */
	public static final String VALUE_UNKNOWN_MISSING = "unknown/missing";

	/** Final field */
	public static final String FIELD_PATIENT_PSEUDONYM = "Pseudonym";
	/** Final field */
	public static final String FIELD_PATIENT_AGE = "Alter";
	/** Final field */
	public static final String FIELD_PATIENT_SEX = "Geschlecht";
	/** Final field */
	public static final String FIELD_CENTER_NAME = "Name des Zentrums";
	/** Final field */
	public static final String FIELD_CENTER_ZIP = "PLZ des Zentrums";
	/** Final field */
	public static final String FIELD_PATIENT_ZIP = "PLZ des Patienten";
	/** Final field */
	public static final String FIELD_PATIENT_DIAGNOSIS = "Diagnose";
	/** Final field */
	public static final String FIELD_PATIENT_DIAGNOSIS_1 = "Diagnose1";
	/** Final field */
	public static final String FIELD_PATIENT_DIAGNOSIS_2 = "Diagnose2";
	/** Final field */
	public static final String FIELD_PATIENT_DISTANCE_LINEAR = "Entfernung-Luftlinie";
	/** Final field */
	public static final String FIELD_PATIENT_DISTANCE_ROUTE = "Entfernung-Route";
	/** Count*/
	public static final String FIELD_COUNT = "Anzahl";
	
	/** Value*/
	public static final String VALUE_PATIENT_SEX_MALE = "M";
	/** Value*/
	public static final String VALUE_PATIENT_SEX_FEMALE = "W";
	/** Value*/
	public static final String VALUE_PATIENT_SEX_DIVERSE = "D";
	/** Value*/
	public static final String VALUE_PATIENT_SEX_UNKNOWN = "U";

	/** Value*/
	public static final String FORMAT_DISTANCE = "##0.##";

	/** Risk threshold*/
	public static final Integer RISK_THRESHOLD = 5;

    /**
     * File loading
     * @param inputFile
     * @return
     * @throws IOException 
     * @throws ParseException 
     */
    public static Data loadPatientLevelData(File inputFile) throws IOException, ParseException {
    	
        // Import process
        DataSource sourceSpecification = DataSource.createCSVSource(inputFile, CHARSET, ';', true);
        
        // Clean columns
        sourceSpecification.addColumn(0, FIELD_PATIENT_PSEUDONYM, DataType.STRING);
        sourceSpecification.addColumn(1, FIELD_PATIENT_AGE, DataType.INTEGER);
        sourceSpecification.addColumn(2, FIELD_PATIENT_SEX, DataType.createOrderedString(
        		new String[] {VALUE_PATIENT_SEX_MALE, VALUE_PATIENT_SEX_FEMALE, VALUE_PATIENT_SEX_DIVERSE, VALUE_PATIENT_SEX_UNKNOWN}));
        sourceSpecification.addColumn(3, FIELD_CENTER_NAME, DataType.STRING);
        sourceSpecification.addColumn(4, FIELD_CENTER_ZIP, DataType.STRING);
        sourceSpecification.addColumn(5, FIELD_PATIENT_ZIP, DataType.STRING);
        sourceSpecification.addColumn(6, FIELD_PATIENT_DIAGNOSIS, DataType.STRING);
        sourceSpecification.addColumn(7, FIELD_PATIENT_DISTANCE_LINEAR, DataType.createDecimal(FORMAT_DISTANCE, Locale.US));
        sourceSpecification.addColumn(8, FIELD_PATIENT_DISTANCE_ROUTE, DataType.createDecimal(FORMAT_DISTANCE, Locale.US));
        
        // Load input file
        DataHandle handle = Data.create(sourceSpecification).getHandle();
        return convertPatientLevel(handle);
    }

//    /**
//     * File loading
//     * @param inputFile
//     * @return
//     * @throws IOException 
//     * @throws ParseException 
//     */
//    public static Data loadDiagnosisLevelData(File inputFile) throws IOException, ParseException {
//    	
//        // Import process
//        DataSource sourceSpecification = DataSource.createCSVSource(inputFile, CHARSET, ';', true);
//        
//        // Clean columns
//        sourceSpecification.addColumn(0, FIELD_PATIENT_PSEUDONYM, DataType.STRING);
//        sourceSpecification.addColumn(1, FIELD_PATIENT_AGE, DataType.INTEGER);
//        sourceSpecification.addColumn(2, FIELD_PATIENT_SEX, DataType.createOrderedString(
//        		new String[] {VALUE_PATIENT_SEX_MALE, VALUE_PATIENT_SEX_FEMALE, VALUE_PATIENT_SEX_DIVERSE, VALUE_PATIENT_SEX_UNKNOWN}));
//        sourceSpecification.addColumn(3, FIELD_CENTER_NAME, DataType.STRING);
//        sourceSpecification.addColumn(4, FIELD_CENTER_ZIP, DataType.STRING);
//        sourceSpecification.addColumn(5, FIELD_PATIENT_ZIP, DataType.STRING);
//        sourceSpecification.addColumn(6, FIELD_PATIENT_DIAGNOSIS, DataType.STRING);
//        sourceSpecification.addColumn(7, FIELD_PATIENT_DISTANCE_LINEAR, DataType.createDecimal(FORMAT_DISTANCE, Locale.US));
//        sourceSpecification.addColumn(8, FIELD_PATIENT_DISTANCE_ROUTE, DataType.createDecimal(FORMAT_DISTANCE, Locale.US));
//        
//        // Load input file
//        DataHandle handle = Data.create(sourceSpecification).getHandle();
//        return convertDiagnosisLevel(handle);
//    }
    
    /**
     * Convert to new handle
     * @param handle
     * @return
     * @throws ParseException 
     */
    private static Data convertPatientLevel(DataHandle handle) throws ParseException {
    	
    	// Result
    	List<String[]> data = new ArrayList<>();
    	
    	// Header
    	String[] header = new String[] {
    			FIELD_PATIENT_PSEUDONYM,
    			FIELD_PATIENT_AGE,
    			FIELD_PATIENT_SEX,
    			FIELD_CENTER_NAME,
    			FIELD_CENTER_ZIP,
    			FIELD_PATIENT_ZIP,
    			FIELD_PATIENT_DIAGNOSIS_1,
    			FIELD_PATIENT_DIAGNOSIS_2,
    			FIELD_PATIENT_DISTANCE_LINEAR,
    			FIELD_PATIENT_DISTANCE_ROUTE
    	};
    	
    	// Header
    	data.add(header);
    	
    	// Obtain diagnoses per patient
    	Map<String, List<String>> diagnoses = new HashMap<>();
    	for (int i=0; i < handle.getNumRows(); i++) {
			String pseudonym = handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_PSEUDONYM));
			String diagnosis = handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_DIAGNOSIS));
			if (!diagnoses.containsKey(pseudonym)) {
				diagnoses.put(pseudonym, new ArrayList<String>());
			}
			List<String> list = diagnoses.get(pseudonym);
			list.add(diagnosis);
			Collections.sort(list);
    	}
    	
    	// List all patients
    	Set<String> done = new HashSet<>();
    	for (int i=0; i < handle.getNumRows(); i++) {
    		
    		// Pseudonym
			String pseudonym = handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_PSEUDONYM));
			
			// Don't process patients twice
			if (done.contains(pseudonym)) {
				continue;
			}
			
			// Other data
			String age = handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_AGE));
			String sex = handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_SEX));
			String centerName = handle.getValue(i, handle.getColumnIndexOf(FIELD_CENTER_NAME));
			String centerZip = handle.getValue(i, handle.getColumnIndexOf(FIELD_CENTER_ZIP));
			String zip = String.valueOf(Integer.valueOf(handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_ZIP))));
			String diagnosis1 = clean(diagnoses.get(pseudonym).get(0));
			String diagnosis2 = diagnoses.get(pseudonym).size() > 1 ? clean(diagnoses.get(pseudonym).get(1)) : "";
			String linear = String.valueOf(Math.round(handle.getDouble(i, handle.getColumnIndexOf(FIELD_PATIENT_DISTANCE_LINEAR))));
			String route = String.valueOf(Math.round(handle.getDouble(i, handle.getColumnIndexOf(FIELD_PATIENT_DISTANCE_ROUTE))));
    		
			// Add
			data.add(new String[] {
				pseudonym,
				age,
				sex,
				centerName,
				centerZip,
				zip,
				diagnosis1,
				diagnosis2,
				linear,
				route
			});
			
			// Mark as done
			done.add(pseudonym);
    	}


    	// Return
    	return Data.create(data);
	}
//
//    /**
//     * Convert to new handle
//     * @param handle
//     * @return
//     * @throws ParseException 
//     */
//    private static Data convertDiagnosisLevel(DataHandle handle) throws ParseException {
//    	
//    	// Result
//    	List<String[]> data = new ArrayList<>();
//    	
//    	// Header
//    	String[] header = new String[] {
//    			FIELD_PATIENT_PSEUDONYM,
//    			FIELD_PATIENT_AGE,
//    			FIELD_PATIENT_SEX,
//    			FIELD_CENTER_NAME,
//    			FIELD_CENTER_ZIP,
//    			FIELD_PATIENT_ZIP,
//    			FIELD_PATIENT_DIAGNOSIS,
//    			FIELD_PATIENT_DISTANCE_LINEAR,
//    			FIELD_PATIENT_DISTANCE_ROUTE
//    	};
//    	
//    	// Header
//    	data.add(header);
//    	
//    	// List all patients
//    	for (int i=0; i < handle.getNumRows(); i++) {
//    		
//			// Data
//			String pseudonym = handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_PSEUDONYM));
//			String age = handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_AGE));
//			String sex = handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_SEX));
//			String centerName = handle.getValue(i, handle.getColumnIndexOf(FIELD_CENTER_NAME));
//			String centerZip = handle.getValue(i, handle.getColumnIndexOf(FIELD_CENTER_ZIP));
//			String zip = handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_ZIP));
//			String diagnosis = clean(handle.getValue(i, handle.getColumnIndexOf(FIELD_PATIENT_DIAGNOSIS)));
//			String linear = String.valueOf(Math.round(handle.getDouble(i, handle.getColumnIndexOf(FIELD_PATIENT_DISTANCE_LINEAR))));
//			String route = String.valueOf(Math.round(handle.getDouble(i, handle.getColumnIndexOf(FIELD_PATIENT_DISTANCE_ROUTE))));
//    		
//			// Add
//			data.add(new String[] {
//				pseudonym,
//				age,
//				sex,
//				centerName,
//				centerZip,
//				zip,
//				diagnosis,
//				linear,
//				route
//			});
//    	}
//
//    	// Return
//    	return Data.create(data);
//	}

    /**
     * Cleans a diagnosis code
     * @param string
     * @return
     */
	private static String clean(String string) {
		return string.replace("!", "").replace("*", "").replace("M908.2", "M90.82");
	}

	/**
     * Writes the data, shuffles rows
     * @param result 
     * @param output
     * @throws IOException 
     */
    public static void writeOutput(Data result, File output) throws IOException {
        CSVDataOutput writer = new CSVDataOutput(output, ';');
		writer.write(result.getHandle().iterator());
    }

    /**
     * Loads a hierarchy
     * @return
     */
	public static Hierarchy loadAgeHierarchy() throws IOException {
		return Hierarchy.create(IO.class.getResourceAsStream("age.csv"), IO.CHARSET);
	}

    /**
     * Loads a hierarchy
     * @return
     */
	public static Hierarchy loadDiagnosisHierarchy() throws IOException {
		return Hierarchy.create(IO.class.getResourceAsStream("diagnosis.csv"), IO.CHARSET);
	}

    /**
     * Loads a hierarchy
     * @return
     */
	public static Hierarchy loadDistanceHierarchy() throws IOException {
		return Hierarchy.create(IO.class.getResourceAsStream("distance.csv"), IO.CHARSET);
	}

    /**
     * Loads a hierarchy
     * @return
     */
	public static Hierarchy loadZipHierarchy() throws IOException {
		return Hierarchy.create(IO.class.getResourceAsStream("zip.csv"), IO.CHARSET);
	}
}
