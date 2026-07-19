# Invoice Generator App

A Flutter app for creating, managing, and exporting professional invoices 
built with Material Design, local (offline) storage, and on-device PDF
generation, sharing, and printing.
## Project Overview
Invoice Generator lets a small business create invoices with full business
and customer details, itemised products/services with quantity, unit price
and optional per-item discount, automatic subtotal/tax/grand-total
calculation, and payment notes. Invoices are stored locally with Hive, can
be searched, edited, duplicated, deleted, and marked Paid / Unpaid /
Overdue, and can be exported as a PDF, shared through the device's native
share sheet (WhatsApp, Email, etc.), or sent to a printer. A Settings screen
lets you configure your company profile, logo, currency, default tax rate,
and invoice number prefix, and a Dashboard summarises total invoices, paid
invoices, unpaid invoices, and total revenue.

## Features

**Core**
- Create invoices with auto-generated, unique, sequential invoice numbers
  (e.g. `INV-001`, configurable prefix)
- Invoice Date / Due Date pickers
- Business information: name, address, email, phone
- Customer information: name, address, email, phone
- Multiple line items with name, quantity, unit price, and optional discount %
- Automatic subtotal, tax, and grand total calculation
- Notes / payment instructions field
- Local, offline persistence (Hive)

**Invoice management**
- View all invoices in a searchable, filterable list
- Search by invoice number or customer name
- Filter by status (All / Paid / Unpaid / Overdue)
- Edit an existing invoice
- Delete an invoice with a confirmation dialog (swipe-to-delete or long-press menu)
- Duplicate an invoice (assigns a new invoice number)
- Mark invoices as Paid / Unpaid / Overdue

**Export & sharing**
- Generate a formatted PDF invoice (business logo, business/customer info,
  itemised table, totals, notes)
- Download/save the PDF to the device
- Share the PDF via the device's native share sheet
- Print the invoice

**Dashboard**
- Total invoices, paid invoices, unpaid invoices, total revenue
- Recent invoices list with quick access

**Settings**
- Upload a company logo (used on generated PDFs)
- Configure company details (used as defaults for new invoices)
- Select currency
- Set a default tax percentage
- Customize the invoice number prefix

**UI**
- Clean, modern Material 3 design with a custom theme
- Responsive layout (scroll views + grid dashboard)
- Empty states when there is no data
- Input validation on all required fields

## Packages Used

| Package          | Purpose                                             |
|------------------|------------------------------------------------------|
| `hive` / `hive_flutter` | Local NoSQL storage for invoices and settings   |
| `pdf`            | Building the invoice PDF document                    |
| `printing`       | Printing and PDF preview/share integration            |
| `share_plus`     | Native share sheet (WhatsApp, email, etc.)             |
| `image_picker`   | Selecting a company logo from the gallery              |
| `path_provider`  | Resolving app document directories for saved files/logo|
| `intl`           | Date formatting                                        |
| `uuid`           | Generating unique internal IDs                          |
| `google_fonts`   | App typography (Poppins)                               |
| `cupertino_icons`| Icon set                                                |

## Project Structure

```
lib/
  screens/       # UI screens (dashboard, invoice, settings)
  widgets/       # Reusable UI components
  models/        # Data models (Invoice, InvoiceItem, BusinessInfo, ...)
  services/       — (business logic helpers)
  utils/          # Validators, currency helpers
  database/       # Hive persistence layer
  pdf/            # PDF generation
  routes/         # Named route table
  core/           # Theme, colors, strings, sizing constants
```
## Notes

- All data is stored locally on-device (Hive); there is no backend/server.
- The first invoice you create will be numbered using the prefix set in
  Settings (default `INV-`), starting at `001`.
