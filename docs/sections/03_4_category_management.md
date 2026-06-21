# 3.4 Category Management

This section details specifications for managing product categories.

---

## 3.4.1 F19 - View Category List / UC-15 View Menu & Categories List

### 3.4.1.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Category Management                                           |
+---------------------------------------------------------------------------------+
|                                                             [ + Add Category ]  |
|                                                                                 |
|  +-----+-------------------+-----------------------------------+-------------+  |
|  | ID  | Category Name     | Description                       | Item Count  |  |
|  +-----+-------------------+-----------------------------------+-------------+  |
|  | 001 | Coffee            | Traditional and espresso-based... | 14          |  |
|  | 002 | Fruit Tea         | Freshly brewed teas with fruit... | 8           |  |
|  +-----+-------------------+-----------------------------------+-------------+  |
|  [Page 1 of 1]                                                                  |
+---------------------------------------------------------------------------------+
```

#### Table 3-20: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Add Category | Button | | | Navigates to Add Category view. |
| 2 | Grid | Grid | | | Lists category listings including ID, name, description, and count. |

### 3.4.1.2 Use Case Description

| Use Case ID | UC-69 | Use Case Name | View Categories List |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Business Admin |
| **Description** | Displays all product categories. |
| **Precondition** | Business Admin is logged in. |
| **Trigger** | Business Admin opens the Category Management section. |
| **Post-Condition** | Product categories list is displayed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Business Admin | Opens Category Management. |
| 2 | Portal | Displays current categories and associated item count metrics. |

---

## 3.4.2 F20 - Add Category / UC-16 Add Category

### 3.4.2.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Category Management > Add Category                            |
+---------------------------------------------------------------------------------+
|  Category Name: [ Coffee                       ]                                |
|                                                                                 |
|  Description:                                                                   |
|  +---------------------------------------------------------------------------+  |
|  | Traditional and espresso-based coffee beverages.                          |  |
|  +---------------------------------------------------------------------------+  |
|                                                                                 |
|                                                [ Save Category ]    [ Cancel ]  |
+---------------------------------------------------------------------------------+
```

#### Table 3-21: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Category Name | Text | Yes | 50 | Unique name of the category. |
| 2 | Description | Text | No | 250 | General description. |
| 3 | Save Category | Button | | | Saves category to database. |
| 4 | Cancel | Button | | | Returns to Category list view without saving. |

### 3.4.2.2 Use Case Description

| Use Case ID | UC-16 | Use Case Name | Add Category |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Business Admin |
| **Description** | Creates a new product category node. |
| **Precondition** | Business Admin is logged in. |
| **Trigger** | Business Admin clicks "+ Add Category". |
| **Post-Condition** | Category is registered. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Business Admin | Enters Name and Description, and clicks "Save Category". |
| 2 | Portal | Validates uniqueness and non-empty name. |
| 3 | Portal | Saves the category and returns to list view. |

#### Alternative Flows
##### AT1: Validation Errors
- **Trigger**: At step 2, name duplicates or is blank.

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Category name cannot be empty and must be unique."` |

---

## 3.4.3 F21 - Update Category / UC-17 Update Category

### 3.4.3.1 Screen Mock-up (Desktop Landscape)
```
+---------------------------------------------------------------------------------+
| HQ Admin Portal > Category Management > Edit Category                           |
+---------------------------------------------------------------------------------+
|  Category Name: [ Coffee                       ]                                |
|                                                                                 |
|  Description:                                                                   |
|  +---------------------------------------------------------------------------+  |
|  | Traditional and espresso-based beverages.                                 |  |
|  +---------------------------------------------------------------------------+  |
|                                                                                 |
|                                                [ Save Changes ]    [ Cancel ]   |
+---------------------------------------------------------------------------------+
```

#### Table 3-22: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Category Name | Text | Yes | 50 | Unique name of the category. |
| 2 | Description | Text | No | 250 | General description. |
| 3 | Save Changes | Button | | | Saves modified category. |
| 4 | Cancel | Button | | | Discards modifications. |

### 3.4.3.2 Use Case Description

| Use Case ID | UC-17 | Use Case Name | Update Category |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Business Admin |
| **Description** | Edits category name or description details. |
| **Precondition** | Category exists. |
| **Trigger** | Business Admin clicks edit icon on list page. |
| **Post-Condition** | Category details are updated. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Business Admin | Edits Name or Description, and clicks "Save Changes". |
| 2 | Portal | Validates inputs. |
| 3 | Portal | Updates details, syncs with active sales screens, and returns to list. |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-30 | Category updates propagate immediately to POS sales screen catalogs. |

---

## 3.4.4 F22 - Delete Category / UC-70 Delete Category

### 3.4.4.1 Screen Mock-up (Desktop Landscape Modal)
```
+--------------------------------------------------------+
| Delete Category Confirmation                           |
|                                                        |
|   Are you sure you want to delete 'Coffee'?            |
|   This will permanently remove the category.           |
|                                                        |
|                [ Cancel ]     [ Confirm Delete ]       |
+--------------------------------------------------------+
```

#### Table 3-23: Screen Definition
| # | Field Name | Type | Mandatory | Max Length | Description |
|---|---|---|---|---|---|
| 1 | Cancel | Button | | | Closes modal without deleting. |
| 2 | Confirm Delete | Button | | | Deletes product category. |

### 3.4.4.2 Use Case Description

| Use Case ID | UC-70 | Use Case Name | Delete Category |
|---|---|---|---|
| **Author** | Antigravity | **Version** | 1.0 |
| **Date** | 2026-05-24 | | |

| Field | Description |
|---|---|
| **Actor** | Business Admin |
| **Description** | Deactivates/deletes an empty category. |
| **Precondition** | Category contains no active items. |
| **Trigger** | Business Admin clicks delete icon on list page. |
| **Post-Condition** | Category is removed. |

#### Main Flows
| Step | Actor | Action |
|---|---|---|
| 1 | Business Admin | Clicks delete on a row. |
| 2 | Portal | Displays Delete Category Confirmation modal. |
| 3 | Business Admin | Clicks "Confirm Delete". |
| 4 | Portal | Deletes category and returns to list view. |

#### Alternative Flows
##### AT1: Category Contains Active Menu Items
- **Trigger**: At step 2, category contains linked menu items that are active (not soft-deleted).

| Sub-step | Actor | Action |
|---|---|---|
| 2.1 | Portal | Displays error message: `"Cannot delete category. Please move, delete, or deactivate the associated active menu items first."` |

#### Business Rules
| ID | Rule Description |
|---|---|
| BR-31 | Cannot delete a category if it contains active menu items. A category can only be deleted if it is empty or all its items are soft-deleted. Upon deletion, any menu items previously belonging to this category will automatically become uncategorized (per BR-62). |
| BR-62 | **Category Soft-Delete Handling**: When a category is soft-deleted/archived, all menu items belonging to it have their category association removed (become uncategorized) to preserve historical sales data and prevent catalog issues. Uncategorized items appear as "Uncategorized" in the HQ menu management view and POS catalogs. |




