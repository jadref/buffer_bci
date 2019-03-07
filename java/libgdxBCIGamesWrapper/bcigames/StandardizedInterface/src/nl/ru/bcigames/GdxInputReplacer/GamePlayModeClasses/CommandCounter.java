/*
 * Copyright (c) 2019 Jeremy Constantin Börker, Anna Gansen, Marit Hagens, Codruta Lugoj, Wouter Loeve, Samarpan Rai and Alex Tichter
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of copyright holder nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */
package nl.ru.bcigames.GdxInputReplacer.GamePlayModeClasses;
/*
 * @author Samarpan Rai (greenspray)
 * The type Command counter.
 */
public class CommandCounter {
    /**
     * The Server key.
     */
    private final int serverKey;
    /**
     * The Gdx key.
     */
    private final int gdxKey;
    /**
     * The Count.
     */
    private Integer count;

    /**
     * Object to hold the key sent by the server and corresponding key for the Gdx system
     *
     * @param serverKey The key sent by Keystroke event from the BufferClient
     * @param gdxKey    The corresponding GDX system key
     */
    public CommandCounter(int serverKey, int gdxKey) {
        this.serverKey = serverKey;
        this.gdxKey = gdxKey;
        this.count = 0;
    }

    /**
     * Gets server key.
     *
     * @return the server key
     */
    public int getServerKey() {
        return serverKey;
    }


    /**
     * Gets gdx key.
     *
     * @return the gdx key
     */
    int getGdxKey() {
        return gdxKey;
    }


    /**
     * Gets count.
     *
     * @return the count
     */
    public Integer getCount() {
        return count;
    }

    /**
     * Sets count.
     *
     * @param count the count
     */
    public void setCount(Integer count) {
        this.count = count;
    }

    /**
     * Incr count.
     */
    public void incrCount(){
        this.count++;
    }
}