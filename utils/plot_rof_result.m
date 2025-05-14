function plot_rof_result(f, u)
    subplot(1,2,1);
    imagesc(f); axis image off; colormap gray;
    title('Original / Noisy');

    subplot(1,2,2);
    imagesc(u); axis image off; colormap gray;
    title('ROF Denoised');
end
