#!/usr/bin/env tclsh
# Experimental clickhouse bindings for Tcl

package require Tcl 8.5
package require http 2.5

namespace eval clickhouse {
	proc connect {user password {host 127.0.0.1} {port 8123}} {
		set result [dict create clickhouse-tcl 1]
		dict set result user $user 
		dict set result password $password
		dict set result host "$host:$port"
		return $result
	}
	
	proc valid {cn} {
		if {! [dict exists $cn clickhouse-tcl]} {
			return 0
		} elseif {! [dict get $cn clickhouse-tcl]} {
			return 0
		}
		return 1
	}
	
	proc query {connection str} {
		if {! [clickhouse::valid $connection]} {
			error "Connection invalid, did you create it via clickhouse::connect?"
		}
		set urlStr "http://[dict get $connection host]/?user=[dict get $connection user]&password=[dict get $connection password]"
		set token [http::geturl $urlStr -query $str]
		set dt [http::data $token]
		set status [http::status $token]
		http::cleanup $token
		if {$status != 200} {
			error "Query failed: $status $dt"
		}
		return $dt
	}
	
	proc join {vals} {
		set result ""
		foreach vl $vals {
			if {[string is digit $vl]} {
				set result "$result $vl"
			} else {
				set result "$result \"$vl\""
			}
			set result "$result,"
		}
		set result [string range $result 0 [expr {[string length $result] - 2}]]
		return $result
	}
	
	proc select {connection what where {output binding} {additional_args {}}} {
		if {! [clickhouse::valid $connection]} {
			error "Connection invalid, did you create it via clickhouse::connect?"
		}
		set customTclList 0
		if {$output == "binding"} {
			set output TSV
			set customTclList 1
		}
		set query "SELECT $what FROM $where FORMAT $output $additional_args;"
		set dt [clickhouse::query $connection $query]
		if {$customTclList} {
			set listing [split $dt \n]
			set resultL {}
			foreach item $listing {
				set row [split $item \t]
				lappend resultL $row
			}
			return $resultL
		}
		return $dt
	}
	
	proc insert {connection where columns values} {
		if {[llength $values] != [llength $columns]} {
			error "All of the values should be specified for each column."
		} elseif {[llength $columns] == 0 || [llength $values] == 0} {
			error "Please specify both the names of the table columns as well as the values to put in."
		}
		set query "INSERT INTO $where ([join $columns ,]) VALUES ([clickhouse::join $values]);"
		return [clickhouse::query $connection $query]
	}
}
