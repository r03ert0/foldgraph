# DO NOT EDIT
# This makefile makes sure all linkable targets are
# up-to-date with anything they link to
default:
	echo "Do not invoke directly"

# Rules to remove targets that are older than anything to which they
# link.  This forces Xcode to relink the targets from scratch.  It
# does not seem to check these dependencies itself.
PostBuild.sphere_skel.Debug:
PostBuild.igl.Debug: /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/Debug/sphere_skel
PostBuild.igl_common.Debug: /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/Debug/sphere_skel
/Users/roberto/Documents/annex-foldgraph/src/register_graph/build/Debug/sphere_skel:
	/bin/rm -f /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/Debug/sphere_skel


PostBuild.sphere_skel.Release:
PostBuild.igl.Release: /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/Release/sphere_skel
PostBuild.igl_common.Release: /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/Release/sphere_skel
/Users/roberto/Documents/annex-foldgraph/src/register_graph/build/Release/sphere_skel:
	/bin/rm -f /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/Release/sphere_skel


PostBuild.sphere_skel.MinSizeRel:
PostBuild.igl.MinSizeRel: /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/MinSizeRel/sphere_skel
PostBuild.igl_common.MinSizeRel: /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/MinSizeRel/sphere_skel
/Users/roberto/Documents/annex-foldgraph/src/register_graph/build/MinSizeRel/sphere_skel:
	/bin/rm -f /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/MinSizeRel/sphere_skel


PostBuild.sphere_skel.RelWithDebInfo:
PostBuild.igl.RelWithDebInfo: /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/RelWithDebInfo/sphere_skel
PostBuild.igl_common.RelWithDebInfo: /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/RelWithDebInfo/sphere_skel
/Users/roberto/Documents/annex-foldgraph/src/register_graph/build/RelWithDebInfo/sphere_skel:
	/bin/rm -f /Users/roberto/Documents/annex-foldgraph/src/register_graph/build/RelWithDebInfo/sphere_skel




# For each target create a dummy ruleso the target does not have to exist
