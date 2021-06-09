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
import org.deidentifier.arx.io.CSVDataOutput;

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
        Data data = IO.loadData(input);
        
        // Output
        File output = new File(input.getParent()+"/output.csv");

        // Write
        CSVDataOutput writer = new CSVDataOutput(output);
        writer.write(data.getHandle().iterator());
    }
}
