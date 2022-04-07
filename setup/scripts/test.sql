-- Table used for logging operations
create table workshop_log 
   (	execution_time timestamp (6), 
	    message varchar2(32000 byte)
   ) 
/

-- Data set listing based on config file on github

create or replace view workshop_datasets as
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
    from ext_datasets a 
/