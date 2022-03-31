create or replace package workshop as 

    /*
    procedure add_dataset
        table_names:  comma separated list of tables.  
                      use ALL to add all tables
        debug_on:     will keep logging tables after a data load
    
    */
    procedure add_dataset(table_names varchar2, debug_on boolean default false);
    
    /* write message to the log */
    procedure write (message in varchar2 default '');
    
    /* Execute a procedure or ddl */
    procedure exec (sql_ddl in varchar2, raise_exception in boolean := false);

end workshop;