/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package nl.dcc.buffer_bci;

/**
 *
 * @author H.G. van den Boorn
 */
// Code barrowed heavily from:
// Copyright (c) 2003-2011, Jodd Team (jodd.org). All Rights Reserved.
import java.util.ArrayList;
import java.util.List;

public class Sscanf {

    public static Object[] scan(String source, String format, Object... params) {
        List<Object> outs = new ArrayList<Object>();
        SscanfFormat sf = new SscanfFormat(source, format);

        for (Object param : params) {
            Object o = parse(sf, param);
            if (o == null) {
                break;
            } else {
                outs.add(o);
            }
        }
        return outs.toArray();
    }

    public static int scan2(String source, String format, Object params[]) {
        SscanfFormat sf = new SscanfFormat(source, format);
        int parseCount = 0;

        for (int i = 0; i < params.length; ++i) {
            params[i] = parse(sf, params[i]);
            if (params[i] == null) {
                break;
            } else {
                ++parseCount;
            }
        }

        return parseCount;
    }

    private static Object parse(SscanfFormat sf, Object param) {
        if (!sf.prepareNextParseParam()) {
            return null;
        }
        Object o = null;

        if (param instanceof Number) {
            if (param instanceof Integer) {
                o = sf.parse((Integer) param);
            } else if (param instanceof Long) {
                o = sf.parse((Long) param);
            } else if (param instanceof Double) {
                //o = sf.parse((Double) param);
            } else if (param instanceof Float) {
                //o = sf.parse((Float) param);
            } else {
                //o = sf.parse((Number)param);
            }
        } else if (param instanceof Character) {
            o = sf.parse((Character) param);
        } else {
            o = sf.parse(param.toString());
        }

        return o;
    }
}
