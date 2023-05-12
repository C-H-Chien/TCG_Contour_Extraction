function  [G, merged_cem, merged_cf_idx, T_junctions] = classify_junction_type_wrt_graph(new_cfrags, new_cfrags_idx, edges, params)    

angle_diff_th = pi/15;
nbr_num_edges = params.nbr_num_edges;
disp('classify junction type wrt topological contour graph...');    
T_junctions = [];
    
% construct factor graph based on curve fragment candidates
G = construct_fac_graph_from_curve_fragments (new_cfrags_idx, new_cfrags);

merged_cem = new_cfrags;
merged_cf_idx = new_cfrags_idx;
  
%%  decide dim 3 nodes merging
for v = 1:length(G.var)

    if(G.var(v).dim ==3) % dim 3 nodes
       

        nbrs_fac = G.var(v).nbrs_fac;

        % do not need to deal with circle anymore
        if(nbrs_fac(1) == nbrs_fac(2) || nbrs_fac(1) == nbrs_fac(3) || nbrs_fac(2) == nbrs_fac(3))
            continue;
        end

        c1_ids = merged_cf_idx{nbrs_fac(1)};
        c2_ids = merged_cf_idx{nbrs_fac(2)};
        c3_ids = merged_cf_idx{nbrs_fac(3)};

        c1 = merged_cem{nbrs_fac(1)};
        c2 = merged_cem{nbrs_fac(2)};
        c3 = merged_cem{nbrs_fac(3)};



        % only consider portion of the curve fragment within
        % neighbourhood of the connecting node
        % always make directions c1 -> node <- c2
        %                                ^
        %                                |
        %                               c3
        %
        % length of contours taken into account must be equal
        cur_nbr = min([nbr_num_edges, size(c1,1), size(c2,1), size(c3,1)]);
        if(c1_ids(1) == G.var(v).actual_edge_id)
            c1 = c1(1:cur_nbr, :);
            % reverse the order of edges
            c1 = fliplr(c1');
            c1 = c1';
            c1_ids = fliplr(c1_ids);
        elseif (c1_ids(end) == G.var(v).actual_edge_id)
            c1 = c1(end-cur_nbr+1:end, :);
        end

        if(c2_ids(1) == G.var(v).actual_edge_id)
            c2 = c2(1:cur_nbr, :);
            % reverse the order of edges
            c2 = fliplr(c2');
            c2 = c2';    
            c2_ids = fliplr(c2_ids);
        elseif (c2_ids(end) == G.var(v).actual_edge_id)
            c2 = c2(end-cur_nbr+1:end, :);
        end    
        
        if(c3_ids(1) == G.var(v).actual_edge_id)
            c3 = c3(1:cur_nbr, :);
            % reverse the order of edges
            c3 = fliplr(c3');
            c3 = c3';    
            c3_ids = fliplr(c3_ids);
        elseif (c3_ids(end) == G.var(v).actual_edge_id)
            c3 = c3(end-cur_nbr+1:end, :);
        end   

        %%%%%%%%%%%%%%%  compute the pairwise diff and merge probs at
        %%%%%%%%%%%%%%%  degree 3 node

%         [cues_diff, probs] = degree_3_node_cues(c1,c2,c3, tmap, hsv_img, edgemap, fmean_0, beta_0, fmean_1, beta_1, nbr_len_th, nbr_num_edges);
        actual_edge = edges(G.var(v).actual_edge_id,:);
        angle_diff_vec = [co_circular_cost(c1, c2) co_circular_cost(c1, c3) co_circular_cost(c2, c3)];
        is_merge = 0;
        if(min(angle_diff_vec) < angle_diff_th)
            is_merge = 1;
        end
        
        % merge decision refer to this vector, saved order: (c1,c2), (c1,c3), (c2,c3)
        probs = exp(-angle_diff_vec);
        G.var(v).p = probs;

        if(is_merge)
            T_junctions = [T_junctions; actual_edge];
            [G, merged_cem, merged_cf_idx] = merge_at_degree_3_node(G, merged_cem, merged_cf_idx, v, actual_edge, c1_ids, c2_ids, c3_ids);
        end
    end

    
end

% only keep the non-empty contours
merged_cem = merged_cem(~cellfun('isempty',merged_cem));
merged_cf_idx = merged_cf_idx(~cellfun('isempty',merged_cf_idx)); 
