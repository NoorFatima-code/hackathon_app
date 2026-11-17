import '../models/student.dart';
import '../models/team_request.dart';

const departments = ['CS', 'SE', 'AI', 'EE', 'BBA'];
const semesters = [4, 5, 6, 7, 8];
const projectTypes = ['Semester Project', 'FYP'];
const availabilityOptions = ['Weekdays', 'Weekends', 'Evenings', 'Flexible'];

const allSkills = [
  'Flutter', 'Dart', 'React', 'Laravel', 'Java', 'Python', 'Machine Learning',
  'UI/UX Design', 'Testing', 'Report Writing', 'Firebase', 'SQL', 'Node.js',
  'Figma', 'Data Analysis',
];

const allInterests = [
  'Mobile Apps', 'Web Development', 'AI', 'Data Science', 'Games',
  'Cyber Security', 'IoT', 'Cloud', 'EdTech', 'Health Tech',
];

const sampleStudents = <Student>[
  Student(id: 's1', name: 'Ayesha Khan', department: 'CS', semester: 5,
      skills: ['Flutter', 'Dart', 'Firebase'], interests: ['Mobile Apps', 'EdTech'],
      projectType: 'Semester Project', availability: 'Weekdays',
      bio: 'Love building clean mobile UIs.'),
  Student(id: 's2', name: 'Hamza Ali', department: 'SE', semester: 6,
      skills: ['React', 'Node.js', 'SQL'], interests: ['Web Development', 'Cloud'],
      projectType: 'FYP', availability: 'Evenings',
      bio: 'Full-stack dev, backend focused.'),
  Student(id: 's3', name: 'Sara Malik', department: 'AI', semester: 7,
      skills: ['Python', 'Machine Learning', 'Data Analysis'], interests: ['AI', 'Health Tech'],
      projectType: 'FYP', availability: 'Flexible',
      bio: 'ML enthusiast looking for FYP team.'),
  Student(id: 's4', name: 'Bilal Ahmed', department: 'CS', semester: 4,
      skills: ['Java', 'SQL', 'Testing'], interests: ['Games', 'Cyber Security'],
      projectType: 'Semester Project', availability: 'Weekends'),
  Student(id: 's5', name: 'Fatima Noor', department: 'SE', semester: 8,
      skills: ['UI/UX Design', 'Figma', 'Report Writing'], interests: ['Mobile Apps', 'EdTech'],
      projectType: 'FYP', availability: 'Weekdays',
      bio: 'Designer who also writes good reports.'),
  Student(id: 's6', name: 'Usman Tariq', department: 'CS', semester: 6,
      skills: ['Laravel', 'SQL', 'React'], interests: ['Web Development', 'Cloud'],
      projectType: 'Semester Project', availability: 'Evenings'),
  Student(id: 's7', name: 'Hira Shahid', department: 'AI', semester: 5,
      skills: ['Python', 'Data Analysis', 'Testing'], interests: ['Data Science', 'AI'],
      projectType: 'Semester Project', availability: 'Flexible'),
  Student(id: 's8', name: 'Zain Abbas', department: 'EE', semester: 7,
      skills: ['Python', 'Java'], interests: ['IoT', 'Cyber Security'],
      projectType: 'FYP', availability: 'Weekends'),
  Student(id: 's9', name: 'Maryam Iqbal', department: 'CS', semester: 4,
      skills: ['Flutter', 'UI/UX Design', 'Figma'], interests: ['Mobile Apps', 'Health Tech'],
      projectType: 'Semester Project', availability: 'Weekdays',
      bio: 'Flutter + design combo.'),
  Student(id: 's10', name: 'Ali Raza', department: 'SE', semester: 8,
      skills: ['Node.js', 'React', 'Firebase'], interests: ['Web Development', 'EdTech'],
      projectType: 'FYP', availability: 'Evenings'),
  Student(id: 's11', name: 'Noman Sheikh', department: 'BBA', semester: 6,
      skills: ['Report Writing', 'Data Analysis'], interests: ['EdTech', 'Health Tech'],
      projectType: 'Semester Project', availability: 'Flexible'),
  Student(id: 's12', name: 'Iqra Javed', department: 'AI', semester: 6,
      skills: ['Machine Learning', 'Python', 'Dart'], interests: ['AI', 'Mobile Apps'],
      projectType: 'FYP', availability: 'Weekdays'),
  Student(id: 's13', name: 'Daniyal Khan', department: 'CS', semester: 5,
      skills: ['Java', 'Testing', 'SQL'], interests: ['Games', 'Cloud'],
      projectType: 'Semester Project', availability: 'Weekends'),
  Student(id: 's14', name: 'Laiba Aslam', department: 'SE', semester: 7,
      skills: ['Flutter', 'Firebase', 'Testing'], interests: ['Mobile Apps', 'Health Tech'],
      projectType: 'FYP', availability: 'Flexible'),
  Student(id: 's15', name: 'Talha Mehmood', department: 'EE', semester: 5,
      skills: ['Python', 'Node.js'], interests: ['IoT', 'Cloud'],
      projectType: 'Semester Project', availability: 'Evenings'),
  Student(id: 's16', name: 'Rabia Anwar', department: 'CS', semester: 8,
      skills: ['Laravel', 'UI/UX Design', 'Report Writing'], interests: ['Web Development', 'EdTech'],
      projectType: 'FYP', availability: 'Weekdays'),
];

/// Judges ke testing ke liye: 3 received requests (accept/reject test)
List<TeamRequest> sampleReceivedRequests() {
  final now = DateTime.now();
  Student s(String id) => sampleStudents.firstWhere((e) => e.id == id);
  return [
    TeamRequest(
      id: 'r1', student: s('s1'),
      message: 'Hi! I need a teammate for my Flutter project. Interested?',
      direction: RequestDirection.received, status: RequestStatus.pending,
      createdAt: now.subtract(const Duration(hours: 2)),
    ),
    TeamRequest(
      id: 'r2', student: s('s3'),
      message: 'Your skills match our FYP idea. Join us?',
      direction: RequestDirection.received, status: RequestStatus.pending,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    TeamRequest(
      id: 'r3', student: s('s5'),
      message: 'Looking for a developer for our UI-heavy app.',
      direction: RequestDirection.received, status: RequestStatus.pending,
      createdAt: now.subtract(const Duration(days: 2)),
    ),
  ];
}