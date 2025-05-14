function assert_near(a, b, tol, msg)
    % ASSERT_NEAR - Throws an error if abs(a - b) > tol
    if any(abs(a - b) > tol)
        error(msg);
    end
end
