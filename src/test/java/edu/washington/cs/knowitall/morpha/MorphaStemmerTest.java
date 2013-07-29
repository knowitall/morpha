package edu.washington.cs.knowitall.morpha;

import org.junit.Assert;
import org.junit.Test;

/**
 * @author sthomson@cs.cmu.edu
 */
public class MorphaStemmerTest {
    @Test
    public void testNullIsRetained() {
        // regression test for https://github.com/knowitall/morpha/issues/1
        // MorphaStemmer.stemToken("null", "JJ") returns ""
        Assert.assertEquals("null", MorphaStemmer.stemToken("null", "JJ"));
        Assert.assertEquals("null", MorphaStemmer.stemToken("nulls", "NN"));
    }
}
