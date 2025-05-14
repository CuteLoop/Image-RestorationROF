function rgb = fake_colorize(gray, plane)
% FAKE_COLORIZE Apply color tint to grayscale image
%   gray  — 2D float image in [0,1]
%   plane — "R", "G1", "G2", or "B"

    if isa(gray, 'uint8') || isa(gray, 'uint16')
        gray = im2single(gray);
    end

    switch upper(plane)
        case 'R'
            rgb = cat(3, gray, zeros(size(gray)), zeros(size(gray)));
        case {'G', 'G1', 'G2'}
            rgb = cat(3, zeros(size(gray)), gray, zeros(size(gray)));
        case 'B'
            rgb = cat(3, zeros(size(gray)), zeros(size(gray)), gray);
        otherwise
            rgb = repmat(gray, 1, 1, 3); % fallback to gray
    end
end
