/*
 *   Copyright 2013 oddlydrawn
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *       http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 */

package com.tumblr.oddlydrawn.stupidworm;

/** @author oddlydrawn */
public class Vector2Marked {
	public float x;
	public float y;
	private boolean marked = false;

	public Vector2Marked () {
	}

	public Vector2Marked (float x, float y) {
		this.x = x;
		this.y = y;
	}

	public boolean getMarked () {
		return marked;
	}

	public void setMarked () {
		marked = true;
	}

	public void removeMarked () {
		marked = false;
	}

	public void set (float x, float y) {
		this.x = x;
		this.y = y;
	}
}
