# clickhouse-tcl
Yandex Clickhouse client bindings to Tcl (require Tcl 8.5 or newer).

Obviously, they are not ready yet, as right now you can only do SELECT as well as connect to the server.

## Example
```
source clickhouse.tcl

set username default
set password somekindofpassword

set mycon [clickhouse::connect $username $password]
set query [clickhouse::select $mycon * system.columns]

foreach row $query {
	puts "DB: [lindex $row 0]"
	puts "Table: [lindex $row 1]"
	puts "Column: [lindex $row 2]"
	puts "Type: [lindex $row 3]"
}

```

## License
Licensed under MIT License.

## API docs
Coming soon...
