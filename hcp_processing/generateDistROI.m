% Load these from Glasser's BALSA repository https://balsa.wustl.edu/RD7g

surf_L=gifti('Q1-Q6_RelatedParcellation210.L.midthickness_MSMAll_2_d41_WRN_DeDrift.32k_fs_LR.surf.gii');
surf_R=gifti('Q1-Q6_RelatedParcellation210.R.midthickness_MSMAll_2_d41_WRN_DeDrift.32k_fs_LR.surf.gii');

labelGifti_left=gifti('Q1-Q6_RelatedParcellation210.L.CorticalAreas_dil_Colors.32k_fs_LR.label.gii');
labelGifti_right=gifti('Q1-Q6_RelatedParcellation210.R.CorticalAreas_dil_Colors.32k_fs_LR.label.gii');


surface_left=struct;
surface_left.vertices=double(surf_L.vertices);
surface_left.faces=double(surf_L.faces);
surface_left.EdgeColor = 'none';
surface_left.FaceColor = 'interp';

surface_right=struct;
surface_right.vertices=double(surf_R.vertices);
surface_right.faces=double(surf_R.faces);
surface_right.EdgeColor = 'none';
surface_right.FaceColor = 'interp';

% After the surfaces have been loaded, then grab the centroid for each parcel

for pcl=1:180,
	inds=find(labelGifti_left.cdata==labelGifti_left.labels.key(pcl+1));
	verts=surface_left.vertices(inds,:);
	centroid=mean(verts,1);
	roi_left(pcl,:)=centroid;
end


for pcl=1:180,
	inds=find(labelGifti_right.cdata==labelGifti_right.labels.key(pcl+1));
	verts=surface_right.vertices(inds,:);
	centroid=mean(verts,1);
	roi_right(pcl,:)=centroid;
end

roi_xyz=[roi_left;roi_right];

figure;patch(surface_left,'FaceColor','white','FaceAlpha',0.5);
hold on;
patch(surface_right,'FaceColor','white','FaceAlpha',0.5);
hold on;
plot3(roi_xyz(1:180,1),roi_xyz(1:180,2),roi_xyz(1:180,3),'.','MarkerSize',36,'LineStyle','none');
camlight
material dull
plot3(roi_xyz(181:360,1),roi_xyz(181:360,2),roi_xyz(181:360,3),'k.','MarkerSize',36,'LineStyle','none');

axis image
view([45 45])
axis off;

dlmwrite('roi_HCP_MMP.txt',roi_xyz);