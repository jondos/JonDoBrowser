/*
 *         _        ___
 *    /\ / /___    / _ \ /\ /\  _ ___
 *   / // // _ \  / // // // // // _ \
 *  / // // // / / ___// // // // // /
 *  \___//_//_/ /_/   /_/ \___/ \_  /
 *                             \___/
 * 
 *  Compunach UnPlug
 *  Copyright (C) 2010, 2011 David Batley <unplug@dbatley.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or (at your option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU Affero General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

/**
 * Common things which need to be loaded everywhere,
 * such as getting settings.
 */
UnPlug2 = {
	UnPlug2 : function () {
		var prefs_service = Components.classes["@mozilla.org/preferences-service;1"]
			.getService(Components.interfaces.nsIPrefService)
		this._prefs = prefs_service.getBranch("extensions.unplug2.");
		this._root_prefs = prefs_service.getBranch("");
		this._locale = Components.classes["@mozilla.org/intl/stringbundle;1"]
			.getService(Components.interfaces.nsIStringBundleService)
			.createBundle("chrome://unplug/locale/strings.txt");
		this._js_console = Components.classes["@mozilla.org/consoleservice;1"]
			.getService(Components.interfaces.nsIConsoleService);
		this._re_trim = /^\s*(.*?)\s*$/m;
		this._unicodeconvert = Components.classes["@mozilla.org/intl/scriptableunicodeconverter"]
			.createInstance(Components.interfaces.nsIScriptableUnicodeConverter);
	},
	
	/**
	 * get_pref
	 * return value of an unplug setting (or def if it doesn't exist)
	 */
	get_pref : function (name, def) {
		return UnPlug2._get_pref(name, def, UnPlug2._prefs);
	},
	
	/**
	 * return value of a pref (or def if it doesn't exist
	 */
	get_root_pref : function (name, def) {
		return UnPlug2._get_pref(name, def, UnPlug2._root_prefs);
	},
	
	_get_pref : function (name, def, prefs) {
		switch (prefs.getPrefType(name)) {
			case prefs.PREF_STRING:
				return prefs.getCharPref(name);
			case prefs.PREF_INT:
				return prefs.getIntPref(name);
			case prefs.PREF_BOOL:
				return prefs.getBoolPref(name);
			default:
				return def;
		}
	},
	
	/**
	 * set_pref
	 * set value of an unplug setting
	 */
	set_pref : function (name, value) {
		switch (typeof(value)) {
			case "number":
				this._prefs.setIntPref(name, value);
				break
			case "boolean":
				this._prefs.setBoolPref(name, value);
				break
			case "string":
				this._prefs.setCharPref(name, value);
				break
			default:
				throw "Cannot set pref of type" + typeof(value);
		}
	},
	
	/**
	 * return a translated version of the string
	 */
	str : function (name) {
		try {
			return this._locale.GetStringFromName(name)
		} catch(e) {
			return "#{" + name + "}";
		}
	},
	
	/**
	 * Print to js console log
	 */
	log : function (msg) {
		this._js_console.logStringMessage("UnPlug2: " + msg);
	},
	
	/**
	 * document.getElelementById for xml files
	 */
	get_element : function (node, tagname, idname) {
		var ellist = node.getElementsByTagName(tagname);
		for (var i=0; i < ellist.length; i++) {
			if (ellist[i].getAttribute("id") == idname) {
				return ellist[i]
			}
		}
		return null;
	},
	
	trim : function (x) {
		if (!x)
			return "";
		return UnPlug2._re_trim.exec(x)[1];
	},
	
	decode : function (encoding, s) {
		this._unicodeconvert.charset = encoding
		return this._unicodeconvert.ConvertToUnicode(s);
	},
	
	toString : function () {
		return "<js:UnPlug2>";
	},
	
	// these should be updated by hand:
	version  : 2.050,
	codename : "beyoglu",
	
	// the following line is auto-generated by upload.sh:
	revision : 201108022339,
	
	// do one-time setup stuff:
	setup_number : 1,
	
	end_of_object : 1 }

// init
UnPlug2.UnPlug2();

