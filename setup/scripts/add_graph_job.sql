create or replace procedure add_graph_job authid current_user as 
begin
    -- CREATE GRAPH (ASYNC JOB)
     workshop.write('create async job that creates and populates the graph');
     begin
        dbms_scheduler.create_job (
           job_name             => 'create_graph',
           job_type             => 'STORED_PROCEDURE',
           job_action           => 'add_graph',
           start_date           => current_timestamp,
           enabled              => true
           );
     end;

     
     workshop.write('adding graph complete.');
end add_graph_job;