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

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.deidentifier.arx.Data;
import org.deidentifier.arx.DataHandle;
import org.deidentifier.arx.DataHandleOutput;

/**
 * Utility class
 * 
 * @author Fabian Prasser
 */
public class Util {

    /**
     * Extract data
     * @param handle
     * @return
     */
    public static Data getData(DataHandle handle) {

        // Prepare
        Iterator<String[]> iter = handle.iterator();
        List<String[]> rows = new ArrayList<String[]>();
        rows.add(iter.next());
        int rowNumber = 0;
        
        // Convert
        while (iter.hasNext()) {
            String[] row = iter.next();
            if (!(handle instanceof DataHandleOutput) || !handle.isOutlier(rowNumber)) {
                rows.add(row);
            }
            rowNumber++;
        }
        
        // Done
        return Data.create(rows);
    }
    
}
