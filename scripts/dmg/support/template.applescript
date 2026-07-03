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
				set statusbar visible to false
				REPOSITION_HIDDEN_FILES_CLAUSE
			end tell

			set opts to the icon view options of container window
			tell opts
				set icon size to ICON_SIZE
				set text size to TEXT_SIZE
				set arrangement to not arranged
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
			close
			open
			-- Force saving of the size
			delay 1

			tell container window
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX - 10, theBottomRightY - 10}
			end tell
		end tell

		delay 1

		tell disk (volumeName as string)
			tell container window
				set statusbar visible to false
				set the bounds to {theXOrigin, theYOrigin, theBottomRightX, theBottomRightY}
			end tell
		end tell

		delay 1
		close every window
	end tell
end run