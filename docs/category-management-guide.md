# Category Management — admin guide

Category Management is where you decide **what each audit standard requires**.
Only admins can open it (menu → *Category Management*).

## The three levels

| Level | What it is | Example |
|---|---|---|
| **Standard** | The audit scheme a company is certified against | SIZA/WIETA, GlobalG.A.P., IPW |
| **Category** | A group of requirements inside one standard | "3. Training" |
| **Document type** | One thing a company must provide | "First aid certificate" |

Every document type belongs to exactly one category, and every category belongs
to exactly one standard.

## Who sees your changes

Everything on this page is **shared by all companies**. A document type you add
appears in the Compliance Tracker of every company that has that standard.

Two related settings live on other pages:

- **Which standards a company has** → *Company Management*.
- **Switching a document type off for one company only** → *Document Settings*.

## Using the page

1. **Pick a standard** with the buttons at the top. Each shows how many
   categories and document types it has.
2. **Pick a category** on the left. Its document types appear on the right.
3. **Search** (right-hand panel) finds document types across every category of
   the selected standard.

On a phone or narrow window the page works in two steps: tap a category to open
its document types, and use the back arrow to return.

### Add a category
*Add category* → choose the standard, enter a name (starting it with a number,
e.g. "3. Training", keeps the order obvious to users) and an optional
description. New categories are added at the bottom.

### Reorder, rename, move or delete a category
Use the **⋮** menu next to the category:

- **Move up / Move down** changes the order companies see.
- **Rename / edit** changes the name or description, or moves the whole category
  (with its document types) to another standard. You're asked to confirm a move,
  because companies on the old standard stop seeing it.
- **Delete** only works once the category has no document types. Move or delete
  them first.

### Add a document type
Select a category → *Add document type*, then choose:

| Option | What it does for companies |
|---|---|
| **They upload a file** | They upload a PDF, photo or Word document. |
| **They fill in a form in the app** | They complete a form instead. The form's questions are set up in the form configuration. |
| **Has an expiry date** | They enter an expiry date. After that date the document shows as expired and needs renewing. Leave it off for documents that never expire, and they won't be asked for a date. |
| **Allow more than one** | They can upload several, e.g. one per worker or per site. |
| **Can be marked "Not applicable"** | They can mark it N/A if it doesn't apply to their farm. |
| **Needs signatures** | It must be signed in the app (choose how many signatures, 1–10). |

The settings appear under each document type as short labels ("File upload",
"Expires", "Can be N/A" …) so you can check them at a glance.

### Edit or move a document type
Click the document type. If you change its category, any documents companies
have already uploaded **move with it**, so they stay together in the Audit
Index. You're told how many first.

### Delete a document type
Only possible when **no company has uploaded anything** for it. If documents
exist, deleting would hide them from the Compliance Tracker and Audit Index, so
the page stops you. To remove it for a company that doesn't need it, switch it
off for that company in *Document Settings*.

## Good to know

- Changes take effect for companies the next time they open a page — no restart
  needed.
- Duplicate names are blocked: two categories in one standard, or two document
  types in one category, can't share a name.
- The old "Company Category Settings" panel was removed. Nothing in the app ever
  read those switches, so they had no effect. Per-company control is in
  *Document Settings*.
