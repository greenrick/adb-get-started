create or replace procedure add_adb_user(user_name varchar2, pwd varchar2) as
    l_count number;
    
    begin
        select count(*)
        into l_count
        from all_users
        where upper(username) = upper(user_name);

        workshop.write('{ create user }');
        if l_count > 0 then
            workshop.write('FAILED: ' || user_name || ' already exists.');
            return;
        end if;
        
        -- Raise exception with an error
        workshop.exec('create user ' || user_name || ' identified by ' || pwd, true);

        workshop.write('{ grant privileges }');
        workshop.exec('grant connect to ' || user_name);
        workshop.exec('grant resource to ' || user_name);
        workshop.exec('grant dwrole to ' || user_name);
        workshop.exec('grant console_developer to ' || user_name);
        workshop.exec('grant oml_developer to ' || user_name);
        workshop.exec('grant graph_developer to ' || user_name);

        workshop.exec('grant unlimited tablespace to ' || user_name);
        workshop.exec('grant create table to ' || user_name);
        workshop.exec('grant create view to ' || user_name);
        workshop.exec('grant create sequence to ' || user_name);
        workshop.exec('grant create procedure to ' || user_name);
        workshop.exec('grant create job to ' || user_name);

        workshop.exec('grant execute on dbms_cloud to ' || user_name);
        workshop.exec('grant execute on dbms_cloud_repo to ' || user_name);
        workshop.exec('grant read on directory data_pump_dir to ' || user_name);
        workshop.exec('grant write on directory data_pump_dir to ' || user_name);
        workshop.exec('grant select on sys.v_$services to ' || user_name);
        workshop.exec('grant select on sys.dba_rsrc_consumer_group_privs to ' || user_name);
        workshop.exec('grant execute on dbms_session to ' || user_name);
        workshop.exec('alter user ' || user_name || ' grant connect through OML$PROXY');
        workshop.exec('alter user ' || user_name || ' grant connect through GRAPH$PROXY_USER');
        workshop.exec('alter user ' || user_name || ' default role connect, resource, dwrole, oml_developer, graph_developer');
            
        commit;

        workshop.write('{ TO DO }');
        workshop.write('Run the following as "ADMIN" in SQL Worksheet to allow your new user to use the SQL Tools');
        workshop.write(q'# begin )
                ords_admin.enable_schema (
                    p_enabled               => TRUE,
                    p_schema                => NEW_USER_NAME,
                    p_url_mapping_type      => 'BASE_PATH',
                    p_auto_rest_auth        => TRUE   
                );
                end;
                / #');

        EXCEPTION when others then
            workshop.write('Unable to create the user.');
            workshop.write(sqlerrm);
            raise;



end add_adb_user;
/