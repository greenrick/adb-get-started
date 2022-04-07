/*    Creates the workshop log and dataset table */
declare
    l_format varchar2(1000) := '{"skipheaders":"0", "delimiter":"\n", "ignoreblanklines":"true"}';
    l_uri    varchar2(1000) := 'https://raw.githubusercontent.com/martygubar/adb-get-started/master/setup/datasets.json';    
begin
   -- drop tables if they exist
   for rec in (  
    select table_name 
    from user_tables
    where table_name in ('WORKSHOP_LOG','EXT_DATASETS')
    ) 
   loop 
      execute immediate 'drop table ' || rec.table_name;
   end loop; 
   
   -- Create the table pointing to data sets
   dbms_cloud.create_external_table(
            table_name => 'EXT_DATASETS',
            file_uri_list => l_uri,
            format => l_format,
            column_list => 'doc varchar2(30000)'
            );       
end;
/

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
    from ext_datasets a;

    
-- Install the workshop base package
declare
    l_git varchar2(4000);
    l_repo_name varchar2(100) := 'adb-get-started';
    l_owner varchar2(100) := 'martygubar';
    l_package_file varchar2(200) := 'setup/scripts/workshop_package.sql';
begin
    -- get a handle to github
    l_git := dbms_cloud_repo.init_github_repo(
                 repo_name       => l_repo_name,
                 owner           => l_owner );

    -- install the package header
    dbms_cloud_repo.install_file(
        repo        => l_git,
        file_path   => l_package_file);

end;
/
