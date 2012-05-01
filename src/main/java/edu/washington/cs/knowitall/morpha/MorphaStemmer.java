/*
 * Copyright (C) 2012 University of Washington
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package edu.washington.cs.knowitall.morpha;

/* author: Michael Schmitz <schmmd@cs.washington.edu>
 *
 * This is a light wrapper for the JFLEX-generated code from the original lex
 * morpha stemmer.  It provides a nicer interface and handles exceptions.
 */

import java.io.StringReader;
import java.util.Scanner;

import uk.ac.susx.informatics.Morpha;

public class MorphaStemmer {
    public String stem(String text) {
        return this.morpha(text);
    }

    public String morpha(String text) {
        String[] textParts = text.split(" ");

        StringBuilder result = new StringBuilder();
        try {
            for (int i = 0; i < textParts.length; i++) {
                Morpha morpha = new Morpha(new StringReader(textParts[i]), false);
                if (result.length() != 0) {
                    result.append(" ");
                }

                result.append(morpha.next());
            }
        }
        // yes, Morpha is cool enough to throw Errors
        // usually when the text contains underscores
        catch (Error e) {
            return text;
        }
        catch (java.io.IOException e) {
            return text;
        }

        String string = result.toString();
        if (string.equals("null")) {
            return "";
        }
        else {
            return string;
        }
    }

    public static void main(String[] args) {
        MorphaStemmer stemmer = new MorphaStemmer();
        Scanner scanner = new Scanner(System.in);

        while (scanner.hasNextLine()) {
            String line = scanner.nextLine();
            System.out.println(stemmer.stem(line));
        }
    }
}
