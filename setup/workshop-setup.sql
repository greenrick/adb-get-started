 create table workshop_log 
   (	execution_time timestamp (6), 
	    message varchar2(32000 byte)
   ) ;

create or replace view datasets as
        with all_datasets as
        (
            select 
                a.doc.table_name as table_name,
                to_number(a.doc.seq) as seq,
                a.doc.source_uri as source_uri,
                a.doc.format as format,
                a.doc.sql as sql,
                a.doc.post_load_proc as post_load_proc,
                a.doc.constraints as constraints,
                a.doc.description as description,
                a.doc.dependencies as dependencies
            from external (
            (
                doc clob     	   
            ) 
            type ORACLE_BIGDATA
            default directory DATA_PUMP_DIR
            access parameters (
                com.oracle.bigdata.fileformat=textfile
                com.oracle.bigdata.csv.rowformat.fields.terminator='\n'
            )
            LOCATION ('https://raw.githubusercontent.com/martygubar/adb-get-started/master/setup/datasets.json')
            ) a 
        )
        select a.* 
        from all_datasets a
        ;   