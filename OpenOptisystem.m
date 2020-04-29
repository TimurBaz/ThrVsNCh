function optsys = OpenOptisystem(directory)
    % create a COM server running OptiSystem
    optsys = actxserver('OptiSystem.Application');

    % Section looks for OptiSystem process and waits for it to start
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Execute the system command
    taskToLookFor = 'OptiSystemx64.exe';
    % Now make up the command line with the proper argument
    % that will find only the process we are looking for.
    commandLine = sprintf('tasklist /FI "IMAGENAME eq %s"', taskToLookFor);
    % Now execute that command line and accept the result into "result".
    [status, result] = system(commandLine);
    % Look for our program's name in the result variable.
    itIsRunning = strfind(lower(result), lower(taskToLookFor));
    while isempty(itIsRunning)
        % pause(0.1)
        [status, result] = system(commandLine);
        itIsRunning = strfind(lower(result), lower(taskToLookFor));
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%
    optsys.Open(directory);
end

