function repeated_matrix = repeat_coordinates(matrix, repeat_counts)
    % This function repeats the rows of a matrix based on the specified repeat counts.
    % matrix: The input Nx3 matrix where each row is a 3D point.
    % repeat_counts: A vector of length N specifying the number of times to repeat each row.
    
    if length(repeat_counts) ~= size(matrix, 1)
        error('The length of repeat_counts must match the number of rows in the matrix.');
    end
    
    repeated_matrix = [];
    for i = 1:length(repeat_counts)
        repeated_matrix = [repeated_matrix; repmat(matrix(i, :), repeat_counts(i), 1)];
    end
end
