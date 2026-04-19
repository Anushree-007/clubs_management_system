# Campus Club Hub

### Institutional Club & Event Intelligence System

---

## Overview

Campus Club Hub is a Flutter-based mobile application designed to centralize and manage all college club data in a structured and audit-friendly format.

It solves the problem of scattered and unorganized club information by providing a single platform for teachers and club chairpersons to view, manage, and analyze club activities, events, finances, and resources.

---

## Problem Statement

In most colleges, club-related data such as:

* event history
* member details
* financial records
* resource usage

is scattered across documents, making it difficult to access, verify, and present during audits (e.g., NAAC).

This application provides a **centralized, structured solution**.

---

## Features

* Role-based login (Teacher / Chairperson)
* Club directory with detailed profiles
* Member management
* Event management system
* Finance tracking (budget, expenses, sponsorships)
* Resource allocation & booking system
* Dashboard with key statistics
* PDF report generation
* Dark / Light theme
* Event gallery 

---

## Tech Stack

* **Frontend:** Flutter (Dart)

* **Backend:** Firebase

  * Authentication
  * Cloud Firestore
  * Firebase Storage

* **Architecture:** MVC (Model-View-Controller)

---

## Project Structure

```
lib/
├── models/
├── views/
├── controllers/
├── services/
├── utils/
└── main.dart
```

---

## User Roles

### Teacher

* View all clubs
* Access reports and analytics
* Approve resource requests

### Chairperson

* Manage own club data
* Add/edit events
* Manage members
* Request resources

---

## Data Managed

* Club details (domain, faculty, status)
* Tenure information
* Member records
* Event data (attendance, type, duration)
* Financial details (budget, expenses, revenue)
* Sponsorship data
* Resource allocation
* Documents (PDF, images, etc.)

---

## Installation

```bash
git clone https://github.com/Anushree-007/clubs_management_system.git
cd clubs_management_system
flutter pub get
flutter run
```

---

## Build APK

```bash
flutter build apk --release
```

APK location:

```
build/app/outputs/flutter-apk/app-release.apk
```

---

## Current Status

```
Under Development.
Some modules are in progress.
```

---

## Contributors

```
Ishan Kadhe - SY-CS-F 03 12413593
Arnav Kale - SY-CS-F 09 12410282
Anushree Kendale - SY-CS-F 50 12411741
Shreya Khatavkar - SY-CS-F 64 12413599
```

---

