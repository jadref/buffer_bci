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
public final class RefObject<T> {

    public T argValue;

    public RefObject(T refArg) {
        argValue = refArg;
    }
}
