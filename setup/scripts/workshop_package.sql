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
/

create or replace package body workshop as

    /* Writes to workshop_log */
    procedure write 
    (
      message in varchar2 default ''
    ) as 
    begin
        dbms_output.put_line(to_char(systimestamp, 'DD-MON-YY HH:MI:SS') || ' - ' || message); 
        
        if message is not null then
            execute immediate 'insert into workshop_log values(:t1, :msg)' 
                    using systimestamp, message;
            commit;
        end if;
    
    end write;
    
    /* Execute a command and log it */
    procedure exec 
    (
      sql_ddl in varchar2,
      raise_exception in boolean := false
  
    ) as 
    begin
        -- Wrapper for execute immediate
        write(sql_ddl);
        execute immediate sql_ddl;
        
        exception
          when others then
            if raise_exception then
                raise;
            else    
                write(sqlerrm);
            end if;
        
    end exec;

  /**
    table_names is a comma separated list of tables
    specify ALL to add all data sets.
  **/  
  procedure add_dataset(table_names varchar2, debug_on boolean) as
    type t_datasets is table of workshop_datasets%rowtype;
    l_datasets t_datasets;
    l_table_names varchar2(4000);
    c_table_names sys.odcivarchar2list := sys.odcivarchar2list();
    l_count number;
    l_opid  number;
    l_load_op_rec user_load_operations%rowtype;
    start_time date := sysdate;
    
  begin
  
    /**
        1. get the list of tables
        2. drop those that existed
        3. create the tables
        4. load the tables
        5. add constraints
        6. run any post-processor
    **/
    write('**');
    write('{ begin }');
    write('debug=' || case when debug_on then 'true' else 'false' end);
    
    -- upper case, no spaces
    l_table_names := replace(trim(upper(table_names)), ' ', '');

    -- Check for ALL tables    
    if l_table_names  = 'ALL' then
        select *
        bulk collect into l_datasets
        from workshop_datasets
        order by seq;     
    else
        -- convert comma separated list of tables
        -- Also, add any dependent tables
        
        with rws as (
          select l_table_names str from dual
        ),
        input_tables as (
            -- comma separated table list
            select *        
            from   workshop_datasets
            where  table_name in ( 
              select regexp_substr (
                       str,
                       '[^,]+',
                       1,
                       level
                     ) value
              from   rws
              connect by level <= 
                length ( str ) - 
                length ( replace ( str, ',' ) ) + 1
                )
        ),
        dependent_tables as (
            -- additional tables that the input tables require
            select      
                jt.dependencies 
            from datasets d, 
                 json_table(upper(dependencies), '$[*]' columns (dependencies path '$')) jt,
                 input_tables i
            where d.table_name = i.table_name
        )
        -- combine the input and dependencies
        select *
        bulk collect into l_datasets
        from workshop_datasets
        where table_name in (select dependencies from dependent_tables)
           or table_name in (select table_name from input_tables)
        order by seq   
        ;
        
    end if;

    write('{ Input tables }');
    write('These tables were requested');
    write(l_table_names);
    write('{ These tables will be added. The list includes dependent tables that were added automatically }');
    
    for i in 1 .. l_datasets.count
    loop
        write('...' || l_datasets(i).table_name);
    end loop;
    
    /**
        Drop tables that will be recreated   
    **/    
    write('{ Will recreate tables that already exist }');
    
    for i in 1 .. l_datasets.count
    loop
        select count(*)
        into l_count
        from user_tables
        where table_name = l_datasets(i).table_name;
        
        if l_count > 0 then
            exec( 'drop table ' || l_datasets(i).table_name || ' cascade constraints');
        end if;            
    end loop;
    write('{ Done dropping tables }');

    /**
        Create the tables
    **/        
    write('{ Creating tables }');
    
    for i in 1 .. l_datasets.count
    loop 
        -- only create tables sourced from object store
        -- otherwise, create the table during the load
        if l_datasets(i).source_uri is null then
            continue;
        end if;
        
        exec (l_datasets(i)."SQL");            
    end loop;
    write('{ Done creating tables }');
    
    /**
        Load the tables
    **/        
    write('{ Loading tables }');
    
    for i in 1 .. l_datasets.count
    loop
        -- load tables that have an object store source
        write ('Loading ' || l_datasets(i).table_name); 
        
        if l_datasets(i).source_uri is null then
            -- this is for sources that are derived from other sources (e.g. CTAS)
            exec (l_datasets(i)."SQL");            
        else                   
            begin
                dbms_cloud.copy_data (
                    table_name        => l_datasets(i).table_name,
                    file_uri_list     => l_datasets(i).source_uri,	
                    format            => l_datasets(i).format,
                    operation_id      => l_opid
                    ); 
                    
                select *
                into l_load_op_rec
                from user_load_operations
                where id = l_opid;
                     
                write ('> status : ' || l_load_op_rec.status);
                write ('> # rows : ' || l_load_op_rec.rows_loaded);
                
                if not debug_on then
                    write('dropping logging tables (enable debugging to preserve logs)');
                    exec('drop table ' || l_load_op_rec.logfile_table);
                    exec('drop table ' || l_load_op_rec.badfile_table);
                end if;
                
                write ('Done loading ' || l_datasets(i).table_name);
            exception
                when others then
                    write(sqlerrm);
            end;
        end if; -- loading data
    end loop;
    write('{ Done loading tables }');
    
    /**
        Add constraints
    **/        
    write('{ Adding constraints }');
    
    for i in 1 .. l_datasets.count
    loop 
        if l_datasets(i).constraints is not null then
            exec (l_datasets(i).constraints);            
        end if;
    end loop;
    write('{ Done adding constraints }'); 
    
    /**
        Run post-load procedures (e.g. spatial metadata updates
    **/        
    write('{ Run post-load procedures }');
    
    for i in 1 .. l_datasets.count
    loop 
        if l_datasets(i).post_load_proc is not null then
            exec ('begin ' || l_datasets(i).post_load_proc || '; end;');            
        end if;
    end loop;
    write('{ Done post-load procedures }'); 
    
    /**
        Done.
    **/
    
    write('** Total time(mm:ss):  ' 
          || to_char(extract(minute from numtodsinterval(sysdate-start_time, 'DAY')), 'FM00')
          || ':' 
          || to_char(extract(second from numtodsinterval(sysdate-start_time, 'DAY')), 'FM00'));
  end add_dataset;

end workshop;
/