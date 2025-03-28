function redraw_res_and_helix( h )
% redraw_res_and_helix( h )
%
% Redraw residue and any other residues associated with its parent helix.
% Call this after dragging.
%
% Input
%  h = graphics handle for residue that was dragged.
%
% (C) R. Das, Stanford University, 2017

delete_crosshair();
res_tag = getappdata( h, 'res_tag' );
residue = getappdata(gca,res_tag );
original_plot_pos = residue.plot_pos;
if isfield( h, 'position' ) ||  strcmp( h.Type, 'text' ) || strcmp( h.Type, 'rectangle' )
    pos = get(h,'position');
    original_residue_plot_pos = residue.plot_pos;
    if length( pos ) == 4 % rectangle
        residue.plot_pos = [ pos(1) + pos(3)/2, pos(2) + pos(4)/2];
    else
        pos = get(h,'position');
        residue.plot_pos = pos(1:2);
    end
    if strcmp( h.Type, 'text' ) & isfield( residue, 'image_boundary' ) & isfield( residue, 'image_offset' );
        residue.image_offset = residue.image_offset + original_residue_plot_pos - residue.plot_pos;
    end
else
    % ligand/protein image_boundary is a special case.
    strcmp( h.Type, 'patch' );
    image_boundary = residue.image_boundary;
    current_image_boundary = [ get( h, 'xdata' ), get( h, 'ydata' )];
    plot_settings = getappdata( gca, 'plot_settings' );
    if isfield( plot_settings, 'ligand_image_scaling' ) image_boundary = image_boundary * plot_settings.ligand_image_scaling; end;
    pos = mean( current_image_boundary ) - mean( image_boundary );
    residue.plot_pos = pos - residue.image_offset;
end
if isfield( residue, 'label_relpos' );    label_plot_pos = get_plot_pos(residue,residue.label_relpos); end;

[residue,switched_helix] = reassign_parent_helix( residue );
if (switched_helix) residue.plot_pos = original_plot_pos; end;

helix = getappdata( gca, residue.helix_tag );
blink_helix_rectangle( helix );
if isfield( residue, 'label_relpos' ); 
    label_plot_pos = label_plot_pos + residue.plot_pos - original_plot_pos;
    residue.label_relpos = get_relpos( label_plot_pos, helix );
end
update_residue_after_helix_reassignment( residue );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function blink_helix_rectangle( helix );
% provide some visual feedback to user.
if isfield(helix,'rectangle')
    color = get( helix.rectangle, 'edgecolor' );
    linew = get( helix.rectangle,'linewidth');
    set( helix.rectangle,'edgecolor','k','linewidth',linew*3 );
    pause(0.1)
    set( helix.rectangle,'edgecolor',color,'linewidth',linew );
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [residue,switched_helix] = reassign_parent_helix( residue )
% If residue is far from parent helix and inside the rectangle for
% another helix, switch its parent.
%
% Relies on plotpos.
%
% Does *not* handle relpos
%
% possible helix parents -- judge based on sequence.
%

     
switched_helix = 0;

% Don't do this for ligands if helix controls are off
plot_settings = getappdata( gca, 'plot_settings' );
if ~plot_settings.show_helix_controls && isfield( residue, 'ligand_partners' ) return; end;

% if the residue was moved into its current helix, don't do anything...
current_helix = getappdata( gca, residue.helix_tag );
if ( check_in_helix_rectangle( residue, current_helix ) )
    switched_helix = 1;
    return;
end

stems = get_stems();   
for n = 1:length( stems )
    other_helix = stems{n};
    if ( check_in_helix_rectangle( residue, other_helix ) )
        switched_helix = 1;
        % do the switch
        current_helix.associated_residues = setdiff( current_helix.associated_residues, residue.res_tag );
        setappdata( gca, current_helix.helix_tag, current_helix );
        
        other_helix.associated_residues = sort( [other_helix.associated_residues, residue.res_tag] );
        setappdata( gca, other_helix.helix_tag, other_helix );
        
        residue.helix_tag = other_helix.helix_tag;
         return;
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function ok = check_neighbor( residue, helix )
% ok = 0;
% plot_settings = getappdata( gca, 'plot_settings' );
% nbr_spacing = plot_settings.bp_spacing;
% for i = 1:length( helix.associated_residues )
%     other_res_tag = helix.associated_residues{i};
%     if strcmp( other_res_tag, residue.res_tag ) continue; end;
%     other_residue = getappdata( gca, other_res_tag);
%     dist = norm( other_residue.plot_pos - residue.plot_pos );
%     if ( dist <= nbr_spacing )
%         ok = 1;
%         return;
%     end
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ok = check_in_helix_rectangle( residue, helix )
if ~isfield( helix, 'rectangle' ) return; end;
pos = get( helix.rectangle, 'Position' );
ok = ( ...
    residue.plot_pos(1) >= pos(1) & ...
    residue.plot_pos(1) <= pos(1)+pos(3) & ...
    residue.plot_pos(2) >= pos(2) & ...
    residue.plot_pos(2) <= pos(2)+pos(4) );

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function stems = get_stems();
vals = getappdata( gca );
objnames = fields( vals );
stems = {};
for n = 1:length( objnames )
    if ~isempty( strfind( objnames{n}, 'Helix_' ) );
        stems = [stems, getappdata( gca, objnames{n} ) ];
    end
end
