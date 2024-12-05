
**ChitChat**

**ChitChat is an advanced messaging application developed using SwiftUI for the user interface and Firebase services for backend functionality. The application supports user account management, real-time messaging, and comprehensive user profile management, offering a secure, encrypted, and seamless communication experience.**

**It incorporates cutting-edge features such as secure user authentication, end-to-end encryption, profile customization, message persistence, time tracking, user search capabilities, and real-time communication.**

**Key Features:**


**User Authentication:**
Implements Firebase Authentication to enable secure user login and account creation, ensuring robust access control.

**Profile Management:**
Leverages Firebase Firestore to allow users to configure and update profile images dynamically.

**Real-Time Messaging:**
Powered by Firebase Realtime Database to deliver instantaneous message exchange with near-zero latency.

**User Search:**
Provides the ability to locate other users via email queries, simplifying the initiation of new conversations.

**End-to-End Encryption:**
Implements an advanced encryption model using the Elliptic-Curve Diffie-Hellman (ECDH) key exchange algorithm and AES-256 encryption. Messages are encrypted locally on the sender's device before transmission and decrypted only on the recipient's device, ensuring absolute confidentiality. 

**Background Processing:**
Utilizes concurrent background threads for tasks such as retrieving user information from Firestore and managing image uploads to Firebase Storage, eliminating main thread congestion and enhancing responsiveness.

**Asynchronous Real-Time Updates:**
Employs asynchronous techniques to synchronize real-time data and retrieve messages, optimizing user experience by ensuring smooth interaction and minimal delays.

**Dispatch Queues:**
Leverages Grand Central Dispatch (GCD) to allocate resource-intensive operations to appropriate dispatch queues, ensuring that UI rendering remains fluid and free from interruptions.

**Performance Optimization:**
By implementing multithreading and efficient resource allocation, the application achieves a performance boost exceeding 100%, delivering a consistently seamless user experience.

**Security Architecture:**
**Encryption at Rest and in Transit:**
Messages and user data are encrypted both at rest and during transmission using Firebase’s security protocols combined with ChitChat’s proprietary enhancements.

**Key Encryption:**
Private keys are further protected thorugh salts and encrytion usign the user's password, preventing brute force attacks and making them impossible. 
And More!!!

ChitChat exemplifies the integration of cutting-edge technology to deliver a robust, secure, and highly efficient messaging platform.

Check it out!

![IMG_3350PNG](https://github.com/user-attachments/assets/f9f72677-a44d-4d79-b12a-710e9ec1d955)
![IMG_3351PNG](https://github.com/user-attachments/assets/2887a6b5-0f05-4aa7-82f3-37a29bb80d6c)
![IMG_3352PNG](https://github.com/user-attachments/assets/e9782f26-65e3-4873-ab31-c4ca73529958)
![IMG_3353PNG](https://github.com/user-attachments/assets/228c23e2-e939-4bcf-8e0d-4e6b678e4cfa)
![IMG_3354PNG](https://github.com/user-attachments/assets/4c1f4ac3-1952-4fd7-ba4a-2b10d0777465)
![IMG_3362PNG](https://github.com/user-attachments/assets/8d22cf49-41cd-4bc5-a7e1-7ed762566b74)
![IMG_3363PNG](https://github.com/user-attachments/assets/cc45953c-1d1f-4577-91ba-cc07c29540f4)
![Chit Chat 1024 x 1024 px-2](https://github.com/user-attachments/assets/0cb412f1-0c01-4c92-8153-5ab5254335e9)
