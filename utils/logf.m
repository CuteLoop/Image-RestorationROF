function logf(fid1, fid2, fmt, varargin)
    msg = sprintf(fmt, varargin{:});
    fprintf(fid1, '%s\n', msg);
    fprintf(fid2, '%s\n', msg);
end
