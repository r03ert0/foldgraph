# DO NOT EDIT
# This makefile makes sure all linkable targets are
# up-to-date with anything they link to
default:
	echo "Do not invoke directly"

# Rules to remove targets that are older than anything to which they
# link.  This forces Xcode to relink the targets from scratch.  It
# does not seem to check these dependencies itself.
PostBuild.icp.Debug:
PostBuild.igl.Debug: /Users/roberto/Documents/annex-foldgraph/src/icp/build/Debug/icp
PostBuild.igl_common.Debug: /Users/roberto/Documents/annex-foldgraph/src/icp/build/Debug/icp
/Users/roberto/Documents/annex-foldgraph/src/icp/build/Debug/icp:
	/bin/rm -f /Users/roberto/Documents/annex-foldgraph/src/icp/build/Debug/icp


PostBuild.icp.Release:
PostBuild.igl.Release: /Users/roberto/Documents/annex-foldgraph/src/icp/build/Release/icp
PostBuild.igl_common.Release: /Users/roberto/Documents/annex-foldgraph/src/icp/build/Release/icp
/Users/roberto/Documents/annex-foldgraph/src/icp/build/Release/icp:
	/bin/rm -f /Users/roberto/Documents/annex-foldgraph/src/icp/build/Release/icp


PostBuild.icp.MinSizeRel:
PostBuild.igl.MinSizeRel: /Users/roberto/Documents/annex-foldgraph/src/icp/build/MinSizeRel/icp
PostBuild.igl_common.MinSizeRel: /Users/roberto/Documents/annex-foldgraph/src/icp/build/MinSizeRel/icp
/Users/roberto/Documents/annex-foldgraph/src/icp/build/MinSizeRel/icp:
	/bin/rm -f /Users/roberto/Documents/annex-foldgraph/src/icp/build/MinSizeRel/icp


PostBuild.icp.RelWithDebInfo:
PostBuild.igl.RelWithDebInfo: /Users/roberto/Documents/annex-foldgraph/src/icp/build/RelWithDebInfo/icp
PostBuild.igl_common.RelWithDebInfo: /Users/roberto/Documents/annex-foldgraph/src/icp/build/RelWithDebInfo/icp
/Users/roberto/Documents/annex-foldgraph/src/icp/build/RelWithDebInfo/icp:
	/bin/rm -f /Users/roberto/Documents/annex-foldgraph/src/icp/build/RelWithDebInfo/icp




# For each target create a dummy ruleso the target does not have to exist
