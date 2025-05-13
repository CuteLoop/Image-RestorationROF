function tf = rof_config()
%ROF_CONFIG  Master switch for GPU usage (overridable in tests)
if isappdata(0,'rof_overrideGPU')
    tf = getappdata(0,'rof_overrideGPU');
else
    tf = true;
end
end