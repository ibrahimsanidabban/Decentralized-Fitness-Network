# Decentralized Fitness Network

A comprehensive blockchain-based fitness ecosystem built on Stacks using Clarity smart contracts.

## Overview

The Decentralized Fitness Network consists of five interconnected smart contracts that manage various aspects of fitness and wellness:

1. **Trainer Certification Contract** - Validates and manages fitness professional qualifications
2. **Workout Tracking Contract** - Monitors exercise progress and achievements
3. **Nutrition Planning Contract** - Creates and manages personalized meal and diet plans
4. **Group Class Scheduling Contract** - Handles fitness session bookings and management
5. **Health Goal Contract** - Sets and tracks personal wellness objectives

## Architecture

Each contract operates independently without cross-contract calls, ensuring modularity and security. The system uses native Clarity data types and functions throughout.

### Key Features

- **Decentralized Trainer Verification**: Trainers can register and get certified through community validation
- **Progress Tracking**: Users can log workouts and track their fitness journey
- **Nutrition Management**: Personalized meal planning with macro tracking
- **Class Scheduling**: Book and manage group fitness sessions
- **Goal Setting**: Set, track, and achieve personal health objectives

## Contract Details

### Trainer Certification (trainer-certification.clar)
- Register new trainers with qualifications
- Community-based certification process
- Trainer profile management
- Certification status tracking

### Workout Tracking (workout-tracking.clar)
- Log individual workout sessions
- Track exercise types, duration, and intensity
- Calculate fitness streaks and achievements
- Personal workout history

### Nutrition Planning (nutrition-planning.clar)
- Create personalized meal plans
- Track daily nutrition intake
- Macro and calorie monitoring
- Dietary preference management

### Group Class Scheduling (group-class-scheduling.clar)
- Schedule fitness classes
- Manage class capacity and bookings
- Track attendance and participation
- Class rating and feedback system

### Health Goal (health-goal.clar)
- Set personal fitness goals
- Track progress toward objectives
- Achievement milestones
- Goal completion rewards

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for testing

### Installation

\`\`\`bash
git clone <repository-url>
cd decentralized-fitness-network
npm install
\`\`\`

### Testing

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy
\`\`\`

## Usage Examples

### Register as a Trainer
\`\`\`clarity
(contract-call? .trainer-certification register-trainer "John Doe" "Certified Personal Trainer" u5)
\`\`\`

### Log a Workout
\`\`\`clarity
(contract-call? .workout-tracking log-workout "strength-training" u60 u8)
\`\`\`

### Create a Meal Plan
\`\`\`clarity
(contract-call? .nutrition-planning create-meal-plan "High Protein" u2000 u150 u50 u200)
\`\`\`

### Schedule a Class
\`\`\`clarity
(contract-call? .group-class-scheduling schedule-class "HIIT Training" u1640995200 u30)
\`\`\`

### Set a Health Goal
\`\`\`clarity
(contract-call? .health-goal set-goal "weight-loss" u10 u30)
\`\`\`

## Testing

The project includes comprehensive tests using Vitest covering all contract functions and edge cases.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## License

MIT License - see LICENSE file for details
