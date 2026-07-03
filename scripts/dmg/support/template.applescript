on run (volumeName)
	tell application "Finder"
		tell disk (volumeName as string)
			open

			set theXOrigin to WINX
			set theYOrigin to WINY
			set theWidth to WINW
			set theHeight to WINH

			set theBottomRightX to (theXOrigin + theWidth)
			set theBottomRightY to (theYOrigin + theHeight)

			tell container window
				set current view to icon view
				set toolbar visible to false
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
				REPOSITION_HIDDEN_FILES_CLAUSE
			end tell

			-- Force icon view + free arrangement (overrides Finder > Settings > General defaults).
			set current view of container window to icon view
			set opts to the icon view options of container window
			tell opts
				set arrangement to not arranged
				set icon size to ICON_SIZE
				set text size to TEXT_SIZE
				set shows item info to false
			end tell
			BACKGROUND_CLAUSE

			-- Positioning
			POSITION_CLAUSE

			-- Hiding
			HIDING_CLAUSE

			-- Application and QL Link Clauses
			APPLICATION_CLAUSE
			QL_CLAUSE

			-- Re-assert view mode before close/open size trick (global Finder prefs can reset view).
			set current view of container window to icon view
			tell icon view options of container window
				set arrangement to not arranged
			end tell

			close
			open
			delay 1

			tell container window
				set current view to icon view
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX - 10, theBottomRightY - 10}
			end tell
			tell icon view options of container window
				set arrangement to not arranged
			end tell
		end tell

		delay 1

		tell disk (volumeName as string)
			tell container window
				set current view to icon view
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
			end tell
			tell icon view options of container window
				set arrangement to not arranged
			end tell
		end tell

		delay 1
		close every window
	end tell
end run