<h1 align="center">🍇 Smart Grape Disease Diagnosis System</h1>

<p align="center">
AI-Powered Mobile Platform for Grape Disease Diagnosis and Treatment Management
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/ASP.NET%20Core-512BD4?style=for-the-badge&logo=dotnet&logoColor=white" alt="ASP.NET Core">
  <img src="https://img.shields.io/badge/FastAPI-009688?style=for-the-badge&logo=fastapi&logoColor=white" alt="FastAPI">
  <img src="https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB" alt="React">
  <img src="https://img.shields.io/badge/YOLOv8-111111?style=for-the-badge" alt="YOLOv8">
  <img src="https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white" alt="SQL Server">
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="MIT License">
</p>

---

## 📚 Table of Contents

- [📖 Overview](#overview)
- [🚨 Problem Statement](#problem-statement)
- [💡 Solution](#solution)
- [⭐ Key Features](#key-features)
- [🏗️ System Architecture](#system-architecture)
  - [Architecture Components](#architecture-components)
    - [📱 Flutter Mobile Application](#flutter-mobile-application)
    - [⚙️ ASP.NET Core Web API](#aspnet-core-web-api)
    - [🤖 AI Service (FastAPI + YOLOv8-Seg)](#ai-service-fastapi--yolov8-seg)
    - [🖥️ React Admin Dashboard](#react-admin-dashboard)
    - [🗄️ SQL Server Database](#sql-server-database)
    - [☁️ External Services](#external-services)
- [🛠️ Technology Stack](#technology-stack)
- [🤖 AI Disease Detection Model](#ai-disease-detection-model)
  - [AI Pipeline](#ai-pipeline)
  - [Model Configuration](#model-configuration)
  - [Prediction Workflow](#prediction-workflow)
  - [Model Performance](#model-performance)
  - [AI Integration](#ai-integration)
- [📦 Project Structure](#project-structure)
- [📂 Repository Components](#repository-components)
  - [📱 Mobile Application](#mobile-application)
  - [⚙️ Backend API](#backend-api)
  - [🤖 AI Service](#ai-service)
  - [🖥️ Admin Dashboard](#admin-dashboard)
- [📋 Documentation](#documentation)
- [📸 Screenshots](#screenshots)

---

<a id="overview"></a>

## 📖 Overview

The **Smart Grape Disease Diagnosis System** is an AI-powered mobile platform designed to help grape farmers detect diseases, apply accurate treatment plans.

Grape farmers often face significant challenges due to the limited availability of agricultural experts, making early disease diagnosis difficult. As a result, diseases are frequently identified too late, pesticides are applied randomly without accurate dosage or follow-up, and many farmers lack access to proper agricultural guidance. These issues increase production costs, reduce treatment effectiveness, and negatively impact crop quality and yield.

To address these challenges, we developed an integrated smart agriculture platform centered around a mobile application.

When a farmer notices symptoms on a grape leaf, they simply capture or upload an image through the mobile application. The image is analyzed using an AI segmentation model (**YOLOv8-Seg**) to identify the disease. Once the diagnosis is completed, the system automatically provides:

- Accurate disease diagnosis.
- Personalized treatment recommendations.
- Step-by-step treatment plan.
- Treatment dose tracking and execution.
- Diagnosis history for monitoring disease progression.

Beyond disease diagnosis, the platform also includes an agricultural knowledge library managed by agricultural specialists through a React-based Admin Dashboard, allowing experts to continuously publish educational articles and treatment plans.

To further support farmers, the system delivers preventive notifications and treatment reminders based on weather conditions, helping reduce disease risks before outbreaks occur.

Together, these components provide farmers with an intelligent decision-support platform that improves disease management, reduces unnecessary pesticide usage, and promotes sustainable agricultural practices.

---

<a id="problem-statement"></a>

## 🚨 Problem Statement

Grape cultivation requires continuous monitoring to detect diseases at their early stages. However, many grape farmers face significant challenges due to the limited availability of agricultural experts and the lack of accessible diagnostic tools.

In many cases, diseases are identified only after they have spread extensively, making treatment more difficult and reducing crop productivity. Without professional guidance, farmers often rely on visual assumptions or personal experience, leading to inaccurate diagnoses.

Another major challenge is the excessive and unstructured use of pesticides. Treatments are frequently applied without accurate dosage recommendations, proper scheduling, or continuous monitoring, resulting in increased production costs, lower treatment effectiveness, environmental risks, and potential damage to crop quality.

Additionally, many farmers have limited access to reliable agricultural knowledge and preventive practices that could help reduce disease outbreaks before they occur.

These challenges highlight the need for an intelligent, accessible, and easy-to-use digital solution capable of supporting farmers in disease diagnosis, treatment management, and preventive agricultural decision-making.

---

<a id="solution"></a>

## 💡 Solution

The Smart Grape Disease Diagnosis System provides an integrated AI-powered platform that assists farmers throughout the entire disease management process.

Using the mobile application, farmers can capture or upload an image of an infected grape leaf. The image is analyzed by an Artificial Intelligence model based on **YOLOv8-Seg**, which identifies the disease and returns an accurate diagnosis within seconds.

Based on the diagnosis, the system automatically generates a treatment recommendation that includes a detailed treatment plan, dosage instructions, and execution tracking, allowing farmers to monitor every treatment step until completion.

The platform extends beyond disease diagnosis by offering several complementary services, including an agricultural knowledge library managed by agricultural specialists, diagnosis history for tracking previous cases, weather monitoring, and preventive notifications generated according to environmental conditions.

Through the integration of Artificial Intelligence, cloud services, and modern software engineering technologies, the platform enables faster diagnosis, more accurate treatment decisions, reduced unnecessary pesticide usage, and improved crop management.

---

<a id="key-features"></a>

## ⭐ Key Features

- 🤖 AI-powered grape disease diagnosis using **YOLOv8-Seg**.
- 📷 Disease detection from grape leaf images.
- 💊 Intelligent treatment recommendations.
- 📋 Step-by-step treatment plans.
- ⏰ Treatment execution tracking and reminder notifications.
- 🌦️ Weather monitoring and preventive disease alerts.
- 📚 Agricultural knowledge library managed by specialists.
- 📝 Diagnosis history and agricultural records.
- 🔔 Push notifications using Firebase Cloud Messaging (FCM).
- 🔐 Secure authentication using Firebase Authentication and JWT.
- 📱 Cross-platform mobile application built with Flutter.
- ⚙️ RESTful Backend API developed with ASP.NET Core.
- 🖥️ React-based Admin Dashboard for content and treatment management.

---

<a id="system-architecture"></a>

## 🏗️ System Architecture

The Smart Grape Disease Diagnosis System follows a distributed multi-service architecture where each component is responsible for a specific domain. The platform separates mobile, backend, artificial intelligence, and administration into independent services that communicate through REST APIs, making the system scalable, maintainable, and easier to extend.

<a id="architecture-components"></a>

### Architecture Components

<a id="flutter-mobile-application"></a>

#### 📱 Flutter Mobile Application

The primary interface used by farmers to:

- Authenticate using Firebase Authentication.
- Capture or upload grape leaf images.
- Receive AI diagnosis results.
- Follow treatment plans.
- Track treatment execution.
- Browse the agricultural knowledge library.
- Receive push notifications.
- Monitor weather conditions.
- View diagnosis history.

<a id="aspnet-core-web-api"></a>

#### ⚙️ ASP.NET Core Web API

Acts as the central business layer responsible for:

- Authentication & Authorization
- User Management
- Farm Management
- Diagnosis Management
- Treatment Management
- Agricultural Library
- Weather Integration
- Push Notifications
- Background Jobs
- Communication with the AI Service

<a id="ai-service-fastapi--yolov8-seg"></a>

#### 🤖 AI Service (FastAPI + YOLOv8-Seg)

A dedicated AI microservice responsible for:

- Receiving uploaded leaf images.
- Running inference using the YOLOv8-Seg segmentation model.
- Detecting grape diseases.
- Returning prediction results and confidence scores to the Backend API.

<a id="react-admin-dashboard"></a>

#### 🖥️ React Admin Dashboard

Provides an administration portal where agricultural specialists can:

- Manage diseases.
- Create treatment plans.
- Publish agricultural articles.
- Manage the knowledge library.
- Maintain platform content.

<a id="sql-server-database"></a>

#### 🗄️ SQL Server Database

Stores all application data including:

- Users
- Farms
- Diagnoses
- Treatment Plans
- Treatment Logs
- Agricultural Library
- Notifications
- Disease Information

<a id="external-services"></a>

#### ☁️ External Services

The platform integrates with external cloud services including:

- Firebase Authentication
- Firebase Cloud Messaging (FCM)
- OpenWeather API

---

<a id="technology-stack"></a>

## 🛠️ Technology Stack

The platform combines modern technologies across mobile development, backend engineering, artificial intelligence, cloud services, and database management to deliver a complete smart agriculture solution.

| Category | Technology | Purpose |
| --- | --- | --- |
| **Mobile Application** | Flutter | Cross-platform mobile application for Android and iOS |
| **Programming Language** | Dart | Mobile application development |
| **Backend Framework** | ASP.NET Core 9 | RESTful API and business logic |
| **Programming Language** | C# | Backend development |
| **Artificial Intelligence** | YOLOv8-Seg | Grape disease detection and segmentation |
| **AI Framework** | FastAPI | AI inference service |
| **Programming Language** | Python | AI model integration |
| **Database** | SQL Server | Centralized relational database |
| **ORM** | Entity Framework Core | Database access and migrations |
| **Authentication** | Firebase Authentication | Secure user authentication |
| **Notifications** | Firebase Cloud Messaging (FCM) | Push notifications |
| **Admin Dashboard** | React | Web-based administration panel |
| **Frontend Language** | TypeScript | Dashboard development |
| **Styling** | Tailwind CSS | Responsive user interface |
| **State Management** | Zustand | Dashboard state management |
| **Build Tool** | Vite | Frontend development and bundling |
| **Weather Service** | OpenWeather API | Weather monitoring and disease prevention |
| **Background Processing** | Hangfire | Scheduled jobs and reminder services |
| **Version Control** | Git & GitHub | Source code management |

---

<a id="ai-disease-detection-model"></a>

## 🤖 AI Disease Detection Model

Artificial Intelligence is the core component of the platform. The system uses a computer vision model based on **YOLOv8m-Seg** to detect grape leaf diseases through instance segmentation.

Unlike traditional image classification, instance segmentation enables the model to identify the diseased region precisely, providing more informative results for diagnosis and future analysis.

<a id="ai-pipeline"></a>

### AI Pipeline

```text
Farmer
    │
    ▼
Capture / Upload Leaf Image
    │
    ▼
Flutter Mobile Application
    │
    ▼
ASP.NET Core Web API
    │
    ▼
FastAPI AI Service
    │
    ▼
YOLOv8m-Seg Model
    │
    ▼
Disease Prediction
    │
    ▼
Backend API
    │
    ▼
Treatment Recommendation
    │
    ▼
Mobile Application
```

<a id="model-configuration"></a>

### Model Configuration

| Parameter | Value |
| --- | --- |
| Model | YOLOv8m-Seg |
| Task | Instance Segmentation |
| Image Size | 640 × 640 |
| Epochs | 100 |
| Batch Size | 16 |
| Early Stopping | Patience = 30 |

<a id="prediction-workflow"></a>

### Prediction Workflow

1. The farmer captures or uploads an image of an infected grape leaf.
2. The image is sent to the Backend API.
3. The Backend forwards the image to the FastAPI AI service.
4. The YOLOv8m-Seg model performs disease segmentation.
5. The predicted disease is returned with its confidence score.
6. The Backend stores the diagnosis.
7. The treatment engine generates a treatment recommendation.
8. The result is displayed in the mobile application.

<a id="model-performance"></a>

### Model Performance

The trained model achieved the following evaluation metrics:

| Metric | Score |
| --- | ---: |
| mAP50 (Bounding Box) | **60.3%** |
| mAP50 (Segmentation Mask) | **58.3%** |
| Precision | **73.3%** |
| Recall | **54.2%** |

The evaluation demonstrates that the model produces reliable predictions with high precision, making it suitable for supporting disease diagnosis while highlighting opportunities for future improvement through larger and more diverse training datasets.

<a id="ai-integration"></a>

### AI Integration

The AI model is deployed as an independent **FastAPI** service.

This architecture allows the Backend API and the AI inference engine to evolve independently, making the system easier to maintain, scale, and upgrade without affecting the mobile application.

---

<a id="project-structure"></a>

## 📦 Project Structure

```text
grape-disease-diagnosis-system
│
├── backend/                # ASP.NET Core Web API
│
├── mobile/                 # Flutter Mobile Application
│
├── ai-service/             # FastAPI + YOLOv8-Seg
│
├── admin-dashboard/        # React Admin Dashboard
│
├── docs/
│   ├── architecture/
│   ├── screenshots/
│   ├── diagrams/
│   └── demo/
│
├── README.md
├── LICENSE
└── .gitignore
```

---

<a id="repository-components"></a>

## 📂 Repository Components

<a id="mobile-application"></a>

### 📱 Mobile Application

Developed using **Flutter**, the mobile application enables farmers to diagnose grape diseases, follow treatment plans, manage agricultural activities, browse educational content, receive notifications, and monitor weather conditions.

<a id="backend-api"></a>

### ⚙️ Backend API

Built with **ASP.NET Core**, the backend serves as the central system responsible for authentication, business logic, data management, communication with the AI service, notifications, weather integration, and treatment management.

<a id="ai-service"></a>

### 🤖 AI Service

The AI service is implemented using **FastAPI** and integrates a **YOLOv8-Seg** model for disease segmentation and diagnosis. It processes uploaded grape leaf images and returns prediction results to the backend.

<a id="admin-dashboard"></a>

### 🖥️ Admin Dashboard

The administration dashboard is built with **React** and enables agricultural specialists to manage diseases, treatment plans, educational articles, and platform content.

---

<a id="documentation"></a>

## 📋 Documentation

Full requirements analysis and system modeling (use cases, diagrams, and specifications):

📄 **[View Requirements Analysis & Modeling (PDF)](https://docs.google.com/viewer?url=https%3A%2F%2Fraw.githubusercontent.com%2FDevAbdullah22%2Fgrape-disease-diagnosis-system%2Fmain%2Fdocs%2FRequirements%2520Analysis%2520and%2520Modeling%2FRequirements%2520Analysis%2520and%2520Modeling.pdf&embedded=true)**

---

<a id="screenshots"></a>

## 📸 Screenshots

Full walkthrough of the mobile app and admin dashboard screens.

📄 [View Screenshots (PDF)](https://docs.google.com/viewer?url=https%3A%2F%2Fraw.githubusercontent.com%2FDevAbdullah22%2Fgrape-disease-diagnosis-system%2Fmain%2Fdocs%2Fscreenshots%2Fscreenshots.pdf&embedded=true)
