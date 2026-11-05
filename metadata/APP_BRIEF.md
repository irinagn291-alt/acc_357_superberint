<!-- gf-brief source=c8be4555aa5db0a18733e6782721481662e40f57f85d53c4a88c5c2949618f81 written=2026-11-05T17:53:10+03:00 -->
# SuperBerint

## What it is

SuperBerint helps egg keepers record collections, track stock and sales, and plan cartons. It also lets users design egg-carton labels and prepare printable sheets.

## Launch and onboarding

On a cold launch, a progress indicator appears while the app starts. The native interface then opens on “Overview”, with the heading “Every egg accounted for.” and the text “From today's collection to the next customer.”

There is no onboarding sequence. A “Help” control opens instructions under “From collection to carton”.

## Screens

### “Overview”

“Overview” shows “Eggs on hand”, “Collected · 7 days”, “Sold · 7 days” and revenue in the selected currency. “Use oldest stock first” lists up to three available collections, oldest first.

- “Log a collection” opens “Collections” on “Planner”.
- “Record a sale” opens “Record sale”.
- A collection row opens “Collection stock”.
- “Help” opens the guide.
- The tab bar opens “Overview”, “Stock”, “Sales”, “Insights” or “Labels”.

### “Stock”

“Stock” lists “Collections · oldest first”. “Find a farm” searches farm names, and “Only available stock” filters out collections with no available eggs. “Collections” opens the collection journal. Tapping a row opens “Collection stock”.

“Collection stock” shows “Eggs remaining”, “Farm”, “Collected”, “Collection age”, “Carton plan”, the optional note and “Stock activity”.

- “Record a sale” opens “Record sale” with that collection selected.
- “Household use or waste” opens “Adjust stock” with that collection selected.
- An activity row opens its record.

### “Sales & activity”

“Sales & activity” lists sales, newest first. “Sales only” can be turned off to include household use and waste. “Customer or farm” searches the list. “Add sale” opens “Record sale”; tapping a record opens its details.

The record shows “Type”, “Farm”, “Eggs”, “Date”, and, for a sale, “Sale total” and “Customer”. It also shows any note. “Delete record” opens “Delete this record and restore stock?”; “Delete and restore stock” removes the record and returns its eggs to the original collection.

### “Record sale” and “Adjust stock”

“Use stock from” selects an available collection, with the oldest selected initially. “Number of eggs” sets the quantity. “Type” offers “Sale”, “Household use” and “Waste / breakage”; “Date” sets the activity date.

For a sale, “Currency” offers “USD”, “GBP”, “EUR”, “CAD” and “AUD”. “Total sale amount” is the total received, and “Customer (optional)” is an optional name. “Note (optional)” is available for all activity. “Save” records the activity and closes the screen; “Cancel” closes it. “Done” dismisses the keyboard.

### “Insights”

“Period” offers “7 days”, “30 days”, “90 days” and “All time”. “Revenue currency” selects “USD”, “GBP”, “EUR”, “CAD” or “AUD”.

The screen shows “Eggs collected”, “Eggs sold”, revenue, “Household / waste”, a “Collection trend” chart and collection and sale counts. Revenue includes sales in the selected currency and is before expenses.

“Export period as CSV” opens the system export flow for collections and activity in the selected period.

### “Labels” / “Label studio”

“Label studio” shows a label preview and “Plan your cartons or create a reusable label design.”

- “Plan a batch” opens “Collections” on “Planner”.
- “Add your farm details”, or the current label-details row, opens “Label details”.
- “Farm”, “Market” and “Minimal” select the “Label style”.
- “Save” saves the current design. It becomes “Saved” when the design matches a saved version.
- “Print design” opens “Print sheet”.
- “My designs” opens saved designs.
- “Help” opens the guide.

### “Label details”

“Farm name” accepts a name, “Eggs per carton” sets the capacity from 1 to 30, “Collection date” selects a date, and “Note” accepts an optional short note. The clear controls are labelled “Clear farm name” and “Clear note” for accessibility.

“Apply” returns the changes to the previous screen. “Cancel” closes the editor; if there are changes, “Discard your changes?” offers “Discard changes” and “Keep editing”. “Done” dismisses the keyboard.

### “My designs”

Saved designs show their farm, date, egg count and style. Tapping one opens it in “Label studio”. Each design’s actions offer “Duplicate”, which opens a copy dated today, and “Delete design”, which asks “Delete this design?” and offers “Delete” or “Cancel”.

“New label” opens a new sample-based design. “Close” returns to the studio. If switching away from an edited, unsaved design, “Save your changes?” offers “Save and continue”, “Continue without saving” and “Cancel”.

### “Collections”

“Planner” and “Journal” switch between the two sections. “Close” dismisses the screen.

In “Planner”, “Eggs collected” accepts a count and “Carton capacity” sets eggs per carton. “Edit label details” opens “Label details”. A valid calculation displays “Carton breakdown”, the number of cartons and labels, and the quantity for a partial carton.

- “Prepare labels” opens “Print sheet” with one label per carton.
- “Save collection” saves the calculation to the journal and adds it to stock.
- “Done” dismisses the keyboard.

“Journal” lists saved collections. Tapping one opens “Collection details”, which shows the saved farm, date, quantity, capacity, style, note and carton breakdown.

- “Reprint labels” opens “Print sheet”.
- “New collection today” starts a new planner entry using the saved details and today’s date.
- “Delete collection” asks for confirmation before removing it.

### “Print sheet”

“Paper size” offers “A4” and “US Letter”. For a single design, “Label copies” changes the number of copies. “Starting position” chooses one of “1 · top left”, “2 · top right”, “3 · middle left”, “4 · middle right”, “5 · bottom left” and “6 · bottom right”.

The preview shows “Sheet [number] of [number]”; “Previous sheet” and “Next sheet” move through it. The screen states “Print at 100% scale and cut along the marks.” “Share PDF” opens the system share flow. “Retry” appears if preparation fails, and “Close” returns to the prior screen.

### “Help”

“Help” explains “Log collections”, “Track sales and stock”, “Review your results”, “Personalize your label”, “Plan the cartons” and “Print your labels”. “Privacy policy” opens “Privacy”. “Contact Us” opens the contact page, with “Done” to close it. “Close” dismisses “Help”.

### Home Screen widget

The small and medium widget displays a collection summary. Tapping it opens “Stock” in the app.

## Features

- Log collections and calculate “Carton breakdown”.
- Track “Eggs on hand”, sales, “Household use” and “Waste / breakage”.
- Review “Collection trend” and revenue by currency and period.
- Export a period as CSV.
- Create, save, duplicate and delete label designs in “Farm”, “Market” and “Minimal” styles.
- Prepare and share printable label sheets on “A4” or “US Letter”, including partial sheets.
- Reprint labels and start a new collection from the “Journal”.
- View a collection summary in a Home Screen widget.

## Behaviours that can look like bugs

- Before a collection is saved, “Overview” says “Save your first collection to start tracking stock. Sales and household use will update the remaining quantity.” Use “Log a collection” to add one.
- An empty or filtered “Stock” says “No matching stock” and “Log a collection or turn off the available-stock filter.” Clear “Find a farm” or turn off “Only available stock” if an existing collection is hidden.
- Before activity exists, “Sales & activity” says “Your activity starts here” and “Record a sale from available stock. Turn off Sales only to see household use and waste.”
- “No eggs available” means there is no eligible stock. Save a collection first; a future-dated collection becomes available on its collection date.
- “Save” in an activity requires an available collection, a positive whole-number quantity no greater than its remaining stock, and a valid total for a sale. The customer is limited to 80 characters and the note to 200. The activity date must fall between the collection date and today.
- “Record a sale” and “Household use or waste” are disabled for a collection with no eggs remaining. Deleting an activity record restores its eggs.
- “Apply” in “Label details” requires a farm name of at most 40 characters and a note of at most 60. The screen displays “Enter a farm name to apply your changes.”, “Shorten the farm name to 40 characters.” or “Shorten the note to 60 characters or leave it blank.” as applicable.
- Before a planner count is entered, the screen displays an example. An invalid count shows “Enter a whole number from 1 to 360.” A plan is limited to 60 cartons; if needed, increase capacity or split the collection.
- After saving, “Save collection” becomes disabled as “Saved to journal”. Changing the count or label creates a new calculation; saving it adds another collection.
- “New collection today” clears the egg count and returns to “Planner”. If another calculation has unsaved changes, “Replace this calculation?” offers “Start new collection” or “Cancel”.
- A collection with activity cannot be deleted until its activity records are deleted. The message says “This collection has sales or stock adjustments. Delete those activity records first to keep your stock accurate.”
- Before any designs are saved, “My designs” says “Your first design will appear here”. Save a design to populate it.
- Before any collections are saved, “Journal” says “Your collections will appear here”. Save a collection in “Planner” to populate it.
- “Export period as CSV” is disabled when the selected period has no collections or activity. Choose another period or add a record.
- “Previous sheet” and “Next sheet” are disabled at the ends of the preview. “Share PDF” appears once the sheet is prepared.

## Starter content and resume

A new label starts with “Willow Farm”, 10 eggs per carton, today’s date, the “Farm” style and “From our hens”. This is sample label content; the saved-design list, collection journal and activity list start empty.

Saved designs, collections and activity remain available for later use. The label studio also restores its draft when available. A collection planner’s unsaved calculation is not presented as a saved journal entry.

## Permissions

None. The app does not declare a permission usage-description string.

## Absent

Login or accounts, in-app purchase, ads, analytics, an account deletion flow and an App Tracking Transparency prompt are absent from the native interface.

User-generated content is present: users enter farm names, notes, collection data, customer names and activity.

## Data and support

Designs, collections and activity are stored on the device. Users can explicitly share a PDF or export a CSV. The app also makes a network request during launch, so it is not accurate to describe all app communication as staying on the device.

“Contact Us” is available in “Help” and opens a contact page.

## Scanning and health

None. The native interface does not scan barcodes or QR codes and does not show health, medical or product-health information or citations.

## Platform

The native interface uses English and US formatting. Currency is selectable independently of region. The app supports iPhone and iPad and requires iOS 17.0 or later. iPhone supports portrait and both landscape orientations; iPad also supports upside-down portrait.

## Category

Productivity.
