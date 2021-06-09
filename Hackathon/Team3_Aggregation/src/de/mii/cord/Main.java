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
import java.text.ParseException;

import org.deidentifier.arx.Data;
import org.deidentifier.arx.exceptions.RollbackRequiredException;

/**
 * Main entry point
 * @author Fabian Prasser
 */
public class Main {

    /**
     * Main entry point
     * @param args
     * @throws IOException 
     * @throws RollbackRequiredException 
     * @throws ParseException 
     */
    public static void main(String[] args) throws IOException, RollbackRequiredException, ParseException {
        
        // Check
        if (args == null || args.length < 1 || args[0] == null || args[0].length() == 0) {
            throw new IllegalArgumentException("You need to specify an input file.");
        }
        
        File input = new File(args[0]);
        if (!input.exists()) {
            throw new IllegalArgumentException("The specified input file doesn't exist.");
        }
        
        // Parse
        Data patientLevelData = IO.loadPatientLevelData(input);
        
        // Aggregation step 1
        IO.writeOutput(Agg1.aggregate1(patientLevelData), new File(input.getParent()+"/agg-1.1.csv"));
        IO.writeOutput(Agg1.aggregate2(patientLevelData), new File(input.getParent()+"/agg-1.2.csv"));
        IO.writeOutput(Agg1.aggregate3(patientLevelData), new File(input.getParent()+"/agg-1.3.csv"));
        IO.writeOutput(Agg1.aggregate4(patientLevelData), new File(input.getParent()+"/agg-1.4.csv"));

        // Aggregation step 2
        IO.writeOutput(Agg2.aggregate1(patientLevelData), new File(input.getParent()+"/agg-2.1.csv"));
        IO.writeOutput(Agg2.aggregate2(patientLevelData), new File(input.getParent()+"/agg-2.2.csv"));
        IO.writeOutput(Agg2.aggregate3(patientLevelData), new File(input.getParent()+"/agg-2.3.csv"));
        IO.writeOutput(Agg2.aggregate4(patientLevelData), new File(input.getParent()+"/agg-2.4.csv"));
    }
}
