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
import java.util.Arrays;

import org.deidentifier.arx.Data;
import org.deidentifier.arx.criteria.KAnonymity;

import de.mii.cord.Anon.Generalization;
import de.mii.cord.Anon.Selection;

/**
 * Aggregates
 * @author Fabian Prasser
 */
public class Aggregation {

	private static final int ICD_GENERALIZATION_LEVEL = 2;

	/**
	 * Breakdown by age and sex
	 * @param data
	 * @result Data
	 * @throws IOException
	 */
	public static Data aggregation1(Data data) throws IOException {
		
		System.out.println("Calculating anonymous breakdown by age and sex");
		
		return Anon.anonymize(	data,
								Arrays.asList( new Selection[] { 	new Selection(IO.FIELD_CENTER_NAME), 
																	new Selection(IO.FIELD_CENTER_ZIP)}),
								Arrays.asList( new Generalization[] { 	new Generalization(IO.FIELD_PATIENT_AGE, IO.loadAgeHierarchy(), 1),
																		new Generalization(IO.FIELD_PATIENT_SEX, null, 0) }),
								new KAnonymity(IO.RISK_THRESHOLD));

	}

	/**
	 * Breakdown by bird flight distance
	 * @param data
	 * @result Data
	 * @throws IOException
	 */
	public static Data aggregation2(Data data) throws IOException {
		
		System.out.println("Calculating anonymous breakdown by bird flight distance");
		
		return Anon.anonymize(	data,
								Arrays.asList( new Selection[] { 	new Selection(IO.FIELD_CENTER_NAME), 
																	new Selection(IO.FIELD_CENTER_ZIP)}),
								Arrays.asList( new Generalization[] {	new Generalization(IO.FIELD_PATIENT_DISTANCE_LINEAR, IO.loadDistanceHierarchy(), 1) }),
								new KAnonymity(IO.RISK_THRESHOLD));

	}

	/**
	 * Breakdown by diagnosis
	 * @param data
	 * @result Data
	 * @throws IOException
	 */
	public static Data aggregation3(Data data) throws IOException {
		
		System.out.println("Calculating anonymous breakdown by diagnosis");
		
		return Anon.anonymize(	data,
								Arrays.asList( new Selection[] { 	new Selection(IO.FIELD_CENTER_NAME), 
																	new Selection(IO.FIELD_CENTER_ZIP)}),
								Arrays.asList( new Generalization[] { 	new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_1, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL),
																		new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_2, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL)}),
								new KAnonymity(IO.RISK_THRESHOLD));

	}

	/**
	 * Breakdown by diagnosis and age
	 * @param data
	 * @result Data
	 * @throws IOException
	 */
	public static Data aggregation4(Data data) throws IOException {
		
		System.out.println("Calculating anonymous breakdown by diagnosis and age");
		
		return Anon.anonymize(	data,
								Arrays.asList( new Selection[] { 	new Selection(IO.FIELD_CENTER_NAME), 
																	new Selection(IO.FIELD_CENTER_ZIP)}),
								Arrays.asList( new Generalization[] { 	new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_1, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL),
																		new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_2, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL),
																		new Generalization(IO.FIELD_PATIENT_AGE, IO.loadAgeHierarchy(), 1)}),
								new KAnonymity(IO.RISK_THRESHOLD));

	}

	/**
	 * Breakdown by diagnosis and sex
	 * @param data
	 * @result Data
	 * @throws IOException
	 */
	public static Data aggregation5(Data data) throws IOException {

		System.out.println("Calculating anonymous breakdown by diagnosis and sex");
		
		return Anon.anonymize(	data,
								Arrays.asList( new Selection[] { 	new Selection(IO.FIELD_CENTER_NAME), 
																	new Selection(IO.FIELD_CENTER_ZIP)}),
								Arrays.asList( new Generalization[] { 	new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_1, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL),
																		new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_2, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL),
																		new Generalization(IO.FIELD_PATIENT_SEX, null, 0)}),
								new KAnonymity(IO.RISK_THRESHOLD));

	}
	/**
	 * Breakdown by diagnosis and bird flight distance
	 * @param data
	 * @result Data
	 * @throws IOException
	 */
	public static Data aggregation6(Data data) throws IOException {
		
		System.out.println("Calculating anonymous breakdown by diagnosis and bird flight distance");
		
		return Anon.anonymize(	data,
								Arrays.asList( new Selection[] { 	new Selection(IO.FIELD_CENTER_NAME), 
																	new Selection(IO.FIELD_CENTER_ZIP)}),
								Arrays.asList( new Generalization[] { 	new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_1, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL),
																		new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_2, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL),
																		new Generalization(IO.FIELD_PATIENT_DISTANCE_LINEAR, IO.loadDistanceHierarchy(), 1)}),
								new KAnonymity(IO.RISK_THRESHOLD));
	}

	/**
	 * Breakdown by diagnosis and zip
	 * @param data
	 * @result Data
	 * @throws IOException
	 */
	public static Data aggregation7(Data data) throws IOException {
		
		System.out.println("Calculating anonymous breakdown by diagnosis and patient zip");
		
		return Anon.anonymize(	data,
								Arrays.asList( new Selection[] { 	new Selection(IO.FIELD_CENTER_NAME), 
																	new Selection(IO.FIELD_CENTER_ZIP)}),
								Arrays.asList( new Generalization[] { 	new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_1, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL),
																		new Generalization(IO.FIELD_PATIENT_DIAGNOSIS_2, IO.loadDiagnosisHierarchy(), ICD_GENERALIZATION_LEVEL),
																		new Generalization(IO.FIELD_PATIENT_ZIP, IO.loadZipHierarchy(), 3)}),
										
								new KAnonymity(IO.RISK_THRESHOLD));
	}

}