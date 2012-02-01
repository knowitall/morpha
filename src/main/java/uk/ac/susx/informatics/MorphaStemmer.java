package uk.ac.susx.informatics;

/* author: Michael Schmitz <schmmd@cs.washington.edu>
 *
 * This is a light wrapper for the morpha stemmer.  It provides a nicer
 * interface and handles exceptions.
 *
 * License: WTFPL <http://sam.zoy.org/wtfpl/COPYING> 
 */

import java.io.StringReader;
import java.util.Scanner;

import uk.ac.susx.informatics.Morpha;

class MorphaStemmer {
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
