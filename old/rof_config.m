function tf = rof_config()
% If a test override flag is set, obey it; otherwise default to true.
if isappdata(0,'rof_test_useGPU_override')
    tf = getappdata(0,'rof_test_useGPU_override');
else
    tf = true;    % ← your project default (set to false if you prefer)
end
end
