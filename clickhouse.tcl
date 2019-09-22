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
	
	proc select {connection what where {output binding} {additional_args {}}} {
		if {! [clickhouse::valid $connection]} {
			error "Connection invalid, did you create it via clickhouse::connect?"
		}
		set urlStr "http://[dict get $connection host]/?user=[dict get $connection user]&password=[dict get $connection password]"
		set customTclList 0
		if {$output == "binding"} {
			set output TSV
			set customTclList 1
		}
		set query "SELECT $what FROM $where FORMAT $output $additional_args;"
		set token [http::geturl $urlStr -query $query]
		set dt [http::data $token]
		set status [http::status $token]
		http::cleanup $token
		if {$status != 200} {
			error "Query failed: $status"
		} elseif {$customTclList} {
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
}
