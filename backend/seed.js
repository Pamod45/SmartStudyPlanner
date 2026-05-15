const admin = require('firebase-admin')
const serviceAccount = require('./serviceAccount.json')

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
})

const db = admin.firestore()
const auth = admin.auth()

// ─── Demo user details ────────────────────────────────────────────────────────

const DEMO_EMAIL    = 'demouser@nibm.lk'
const DEMO_PASSWORD = 'Demo123'

// ─── Helpers ──────────────────────────────────────────────────────────────────

function ts(date) {
    return admin.firestore.Timestamp.fromDate(date)
}

async function getOrCreateAuthUser() {
    try {
        const existing = await auth.getUserByEmail(DEMO_EMAIL)
        console.log(`Auth user already exists — uid: ${existing.uid}`)
        return existing.uid
    } catch (e) {
        if (e.code === 'auth/user-not-found') {
            const created = await auth.createUser({
                email:         DEMO_EMAIL,
                password:      DEMO_PASSWORD,
                displayName:   'Demo User',
                emailVerified: true,
                username:      'demouser',
            })
            console.log(`Auth user created — uid: ${created.uid}`)
            return created.uid
        }
        throw e
    }
}

// ─── Seed ─────────────────────────────────────────────────────────────────────

async function seed() {
    const uid = await getOrCreateAuthUser()

    // ── User document ──────────────────────────────────────────────────────────
    const userRef = db.collection('users').doc(uid)
    const userSnap = await userRef.get()

    if (!userSnap.exists) {
        await userRef.set({
            id:              uid,
            email:           DEMO_EMAIL,
            displayName:     'DemoIOS',
            institute:       'NIBM',
            authProvider:    'Email',
            domain:          'Software Engineering',
            isEmailVerified: true,
            createdAt:       ts(new Date('2026-05-01T00:00:00Z')),
            lastLoginAt:     ts(new Date('2026-05-13T00:00:00Z')),
        })
        console.log('User document created')
    } else {
        console.log('User document already exists — skipping')
    }

    // ── User settings document ─────────────────────────────────────────────────
    const settingsRef = db.collection('userSettings').doc(uid)
    const settingsSnap = await settingsRef.get()

    if (!settingsSnap.exists) {
        await settingsRef.set({
            id:                              uid,
            userId:                          uid,
            accessibilityFontSize:           1,
            breakDurationMinutes:            10,
            calendarSyncEnabled:             true,
            dailyStudyGoalHours:             3,
            darkModeEnabled:                 true,
            deadlineAlertsEnabled:           true,
            deadlineReminderDaysBefore:      3,
            deadlineReminderHoursBefore:     1,
            highContrastEnabled:             true,
            notificationsEnabled:            true,
            preferredSessionDurationMinutes: 60,
            preferredStudyTime:              'Morning',
            quizReminderMinutesAfter:        0,
            quizzesPendingReminders:         true,
            reduceMotionEnabled:             true,
            sessionReminderMinutesBefore:    5,
            sessionRemindersEnabled:         true,
            siriIntegrationEnabled:          true,
            soundEnabled:                    true,
            syncStatus:                      '',
            theme:                           'system',
            weeklyStudyGoalDays:             5,
            widgetConfiguration:             'Default Widget Data',
            updatedAt:                       ts(new Date('2026-05-13T21:44:05Z')), // 3:14:05 AM UTC+5:30
        })
        console.log('User settings created')
    } else {
        console.log('User settings already exist — skipping')
    }

    // ── Subjects ───────────────────────────────────────────────────────────────
    const subjectDefs = [
        { name: 'iOS',             colorHex: '#3B82F6', iconName: 'iphone'   },
        { name: 'Web Application', colorHex: '#10B981', iconName: 'globe'    },
        { name: 'Computer Vision', colorHex: '#EC4899', iconName: 'eye.fill' },
    ]

    // Track created/existing subject IDs by name for use in later sections.
    const subjectIds = {}

    for (const def of subjectDefs) {
        const existing = await db.collection('subjects')
            .where('userId', '==', uid)
            .where('name',   '==', def.name)
            .limit(1)
            .get()

        if (!existing.empty) {
            subjectIds[def.name] = existing.docs[0].id
            console.log(`Subject "${def.name}" already exists — skipping`)
            continue
        }

        const subjectId = db.collection('subjects').doc().id
        await db.collection('subjects').doc(subjectId).set({
            id:                 subjectId,
            userId:             uid,
            name:               def.name,
            colorHex:           def.colorHex,
            iconName:           def.iconName,
            notes:              '',
            targetHoursPerWeek: 0,
            totalHoursStudied:  0,
            resourceCount:      0,
            topicCount:         0,
            deadlineIds:        [],
            resourceIds:        [],
            sessionIds:         [],
            noteFilePaths:      [],
            isArchived:         false,
            syncStatus:         'synced',
            createdAt:          ts(new Date('2026-05-01T00:00:00Z')),
            updatedAt:          ts(new Date('2026-05-01T00:00:00Z')),
        })
        subjectIds[def.name] = subjectId
        console.log(`Subject "${def.name}" created ✅`)
    }

    // ── Deadlines (iOS) ────────────────────────────────────────────────────────
    const iosId       = subjectIds['iOS']
    const iosColorHex = '#3B82F6'

    const deadlineDefs = [
        {
            name:         'iOS CW',
            tag:          '#CW',
            dueDate:      new Date('2026-05-13T18:00:00Z'),
            reminderDate: new Date('2026-05-12T18:00:00Z'),
        },
        {
            name:         'iOS Submission',
            tag:          '#Submission',
            dueDate:      new Date('2026-05-16T18:00:00Z'),
            reminderDate: new Date('2026-05-15T18:00:00Z'),
        },
    ]

    const newDeadlineIds = []

    for (const def of deadlineDefs) {
        const existing = await db.collection('deadlines')
            .where('subjectId', '==', iosId)
            .where('name',      '==', def.name)
            .limit(1)
            .get()

        if (!existing.empty) {
            console.log(`Deadline "${def.name}" already exists — skipping`)
            continue
        }

        const deadlineId = db.collection('deadlines').doc().id
        await db.collection('deadlines').doc(deadlineId).set({
            id:               deadlineId,
            userId:           uid,
            subjectId:        iosId,
            subjectColorHex:  iosColorHex,
            name:             def.name,
            tag:              def.tag,
            dueDate:          ts(def.dueDate),
            hasReminder:      true,
            reminderDate:     ts(def.reminderDate),
            isHighPriority:   false,
            notes:            '',
            priority:         'medium',
            status:           'upcoming',
            linkedSessionIds: [],
            notificationId:   null,
            syncStatus:       'synced',
            createdAt:        ts(new Date('2026-05-01T00:00:00Z')),
            updatedAt:        ts(new Date('2026-05-01T00:00:00Z')),
        })
        newDeadlineIds.push(deadlineId)
        console.log(`Deadline "${def.name}" created ✅`)
    }

    // Add the new deadline IDs to the iOS subject's deadlineIds array.
    if (newDeadlineIds.length > 0) {
        await db.collection('subjects').doc(iosId).update({
            deadlineIds: admin.firestore.FieldValue.arrayUnion(...newDeadlineIds),
            updatedAt:   ts(new Date()),
        })
        console.log(`iOS subject deadlineIds updated ✅`)
    }

    // ── Resources (iOS) ────────────────────────────────────────────────────────
    const resourceDefs = [
        {
            name:         'Swift Basics',
            resourceType: 'Note',
            size:         '',
            content:      'YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGvECQLDBUZISgzNDU2RkxSV2prcXl6ZXt8gISIkpqbnqansba7v8RVJG51bGzUDQ4PEBESExRYTlNTdHJpbmdfEA9OU0F0dHJpYnV0ZUluZm9cTlNBdHRyaWJ1dGVzViRjbGFzc4ACgCGABIAj0hAWFxhZTlMuc3RyaW5ngANfEQWnVmFyaWFibGVzICYgY29uc3RhbnRzCgpVc2UgdmFyIGZvciBtdXRhYmxlIHZhbHVlcyBhbmQgbGV0IGZvciBjb25zdGFudHMuIFN3aWZ0IGluZmVycyB0eXBlcyBhdXRvbWF0aWNhbGx5Lgp2YXIgc2NvcmUgPSAwCmxldCBuYW1lID0gIlN3aWZ0Igp2YXIgcGk6IERvdWJsZSA9IDMuMTQKTG9vcHMKZm9yLWluIGl0ZXJhdGVzIG92ZXIgcmFuZ2VzIG9yIGNvbGxlY3Rpb25zLiB3aGlsZSBydW5zIHVudGlsIGEgY29uZGl0aW9uIGlzIGZhbHNlLgpmb3IgaSBpbiAxLi4uNSB7CiAgcHJpbnQoaSkKfQp2YXIgeCA9IDMKd2hpbGUgeCA+IDAgeyB4IC09IDEgfQoKQ29uZGl0aW9uYWxzCgpTd2lmdCdzIHN3aXRjaCBzdXBwb3J0cyBwYXR0ZXJuIG1hdGNoaW5nIGFuZCByYW5nZXMgbm8gZmFsbHRocm91Z2ggYnkgZGVmYXVsdC4KaWYgc2NvcmUgPiA4MCB7CiAgcHJpbnQoIlBhc3MiKQp9CnN3aXRjaCBzY29yZSB7CmNhc2UgOTAuLi4xMDA6IHByaW50KCJBIikKY2FzZSA3MC4uPDkwOiAgcHJpbnQoIkIiKQpkZWZhdWx0OiAgICAgICAgcHJpbnQoIkMiKQp9CgpGdW5jdGlvbnMKCmVmaW5lZCB3aXRoIGZ1bmMuIFBhcmFtZXRlcnMgaGF2ZSBsYWJlbHMgYW5kIHR5cGVzLiBVc2UgLT4gdG8gc3BlY2lmeSBhIHJldHVybiB0eXBlLgpmdW5jIGdyZWV0KG5hbWU6IFN0cmluZykgLT4gU3RyaW5nIHsKICByZXR1cm4gIkhlbGxvLCBcKG5hbWUpISIKfQpncmVldChuYW1lOiAiUHVidWR1IikKCkNsb3N1cmVzClNlbGYtY29udGFpbmVkIGJsb2NrcyBvZiBmdW5jdGlvbmFsaXR5LiBIZWF2aWx5IHVzZWQgaW4gY2FsbGJhY2tzLCBzb3J0aW5nLCBhbmQgU3dpZnRVSS4KbGV0IG51bXMgPSBbMywgMSwgMl0KbGV0IHNvcnRlZCA9IG51bXMuc29ydGVkIHsKICAkMCA8ICQxCn0KCk9wdGlvbmFscwoKT3B0aW9uYWxzIHJlcHJlc2VudCBhIHZhbHVlIHRoYXQgbWF5IG9yIG1heSBub3QgZXhpc3QuIFVud3JhcCBzYWZlbHkgd2l0aCBpZiBsZXQgb3IgZ3VhcmQgbGV0Lgp2YXIgYWdlOiBJbnQ/ID0gbmlsCmFnZSA9IDI1CmlmIGxldCBhID0gYWdlIHsKICBwcmludCgiQWdlIGlzIFwoYSkiKQp9CgpTdHJ1Y3RzICYgY2xhc3NlcwoKU3RydWN0cyBhcmUgdmFsdWUgdHlwZXMgKGNvcGllZCBvbiBhc3NpZ25tZW50KS4gQ2xhc3NlcyBhcmUgcmVmZXJlbmNlIHR5cGVzLiBQcmVmZXIgc3RydWN0cyBpbiBTd2lmdC4Kc3RydWN0IFVzZXIgewogIHZhciBuYW1lOiBTdHJpbmcKICB2YXIgYWdlOiBJbnQKfQpsZXQgdSA9IFVzZXIobmFtZTogIkFuYSIsIGFnZTogMjgpCgpFbnVtcwoKRW51bXMgZGVmaW5lIGEgZ3JvdXAgb2YgcmVsYXRlZCB2YWx1ZXMuIFN3aWZ0IGVudW1zIGNhbiBjYXJyeSBhc3NvY2lhdGVkIHZhbHVlcyBhbmQgaGF2ZSBtZXRob2RzLgplbnVtIERpcmVjdGlvbiB7CiAgY2FzZSBub3J0aCwgc291dGgsIGVhc3QsIHdlc3QKfQpsZXQgZCA9IERpcmVjdGlvbi5ub3J0aNIaGxwdWiRjbGFzc25hbWVYJGNsYXNzZXNfEA9OU011dGFibGVTdHJpbmejHh8gXxAPTlNNdXRhYmxlU3RyaW5nWE5TU3RyaW5nWE5TT2JqZWN00iIQIydaTlMub2JqZWN0c6MkJSaABYAYgB6AINMpIhAqLjJXTlMua2V5c6MrLC2ABoAHgAijLzAxgAmAC4ANgBVXTlNDb2xvcl8QEE5TUGFyYWdyYXBoU3R5bGVWTlNGb2502Dc4OTo7EDw9Pj9AQUJDREVfEBVVSUNvbG9yQ29tcG9uZW50Q291bnRXVUlHcmVlblZVSUJsdWVXVUlBbHBoYVVOU1JHQlVVSVJlZFxOU0NvbG9yU3BhY2UQBCI/ZeXmIj9k5OUiP4AAAE8QETAuOTA2IDAuODk4IDAuODk0gAoiP2fn6BAC0xobR0hJSlskY2xhc3NoaW50c1dVSUNvbG9yokggoUtXTlNDb2xvctNNEE5PUFFaTlNUYWJTdG9wc1tOU0FsaWdubWVudIAAgAwQBNIaG1NUXxAXTlNNdXRhYmxlUGFyYWdyYXBoU3R5bGWjVVYgXxAXTlNNdXRhYmxlUGFyYWdyYXBoU3R5bGVfEBBOU1BhcmFncmFwaFN0eWxl21hZWltcEF1eX2BhYmJjZGVmRWVPZGlfECJVSUZvbnRNYXhpbXVtUG9pbnRTaXplQWZ0ZXJTY2FsaW5nXxAZVUlGb250UG9pbnRTaXplRm9yU2NhbGluZ18QEFVJRm9udERlc2NyaXB0b3JWTlNOYW1lVk5TU2l6ZVxVSUZvbnRUcmFpdHNfEA9VSUZvbnRQb2ludFNpemVfEBlVSUZvbnRUZXh0U3R5bGVGb3JTY2FsaW5nWlVJRm9udE5hbWVcVUlTeXN0ZW1Gb250IwAAAAAAAAAAgA+ADiNAMAAAAAAAAIAXgACADgleLlNGVUktU2VtaWJvbGTTbBBtbm9wXxAXVUlGb250RGVzY3JpcHRvck9wdGlvbnNfEBpVSUZvbnREZXNjcmlwdG9yQXR0cmlidXRlcxKAAIQEgBaAENMpIhBydTKic3SAEYASonZ3gBOAFIAVXxATTlNGb250U2l6ZUF0dHJpYnV0ZV8QGE5TQ1RGb250VUlVc2FnZUF0dHJpYnV0ZV8QFUNURm9udEVtcGhhc2l6ZWRVc2FnZdIaG31+XE5TRGljdGlvbmFyeaJ/IFxOU0RpY3Rpb25hcnnSGhuBgl8QEFVJRm9udERlc2NyaXB0b3KigyBfEBBVSUZvbnREZXNjcmlwdG9y0xobR4WGh1ZVSUZvbnSihSChNdMpIhCJjTKjKywtgAaAB4AIoy8wkIAJgAuAGYAV21hZWltcEF1eX2BhYmKTlGVmlmVPlGmAG4AagBcQAIAAgBoJXS5TRlVJLVJlZ3VsYXLTbBBtbm+dgBaAHNMpIhCfojKic3SAEYASonakgBOAHYAVXxASQ1RGb250UmVndWxhclVzYWdl0ykiEKisMqMrLC2ABoAHgAijL66QgAmAH4AZgBXUTbJOEE+0UVBfEBJOU1dyaXRpbmdEaXJlY3Rpb26AABABgAzSGhu3uF5OU011dGFibGVBcnJheaO5uiBeTlNNdXRhYmxlQXJyYXlXTlNBcnJhedK8EL2+V05TLmRhdGFPECcVAKYCAQwA1AEBCQCXAQECAhcBCACXAQEJAKkBAREAvgEBBQCuAQGAItIaG8DBXU5TTXV0YWJsZURhdGGjwsMgXU5TTXV0YWJsZURhdGFWTlNEYXRh0hobxcZfEBJOU0F0dHJpYnV0ZWRTdHJpbmeixyBfEBJOU0F0dHJpYnV0ZWRTdHJpbmcACAARABoAJAApADIANwBJAEwAUQBTAHoAgACJAJIApACxALgAugC8AL4AwADFAM8A0QZ8BoEGjAaVBqcGqwa9BsYGzwbUBt8G4wblBucG6QbrBvIG+gb+BwAHAgcEBwgHCgcMBw4HEAcYBysHMgdDB1sHYwdqB3IHeAd+B4sHjQeSB5cHnAewB7IHtwe5B8AHzAfUB9cH2QfhB+gH8wf/CAEIAwgFCAoIJAgoCEIIVQhsCJEIrQjACMcIzgjbCO0JCQkUCSEJKgksCS4JNwk5CTsJPQk+CU0JVAluCYsJkAmSCZQJmwmeCaAJogmlCacJqQmrCcEJ3An0CfkKBgoJChYKGwouCjEKRApLClIKVQpXCl4KYgpkCmYKaApsCm4KcApyCnQKiwqNCo8KkQqTCpUKlwqYCqYKrQqvCrEKuAq7Cr0KvwrCCsQKxgrICt0K5AroCuoK7AruCvIK9Ar2CvgK+gsDCxgLGgscCx4LIwsyCzYLRQtNC1ILWguEC4YLiwuZC50LqwuyC7cLzAvPAAAAAAAAAgEAAAAAAAAAyAAAAAAAAAAAAAAAAAAAC+Q=',
            localFilePath: null,
            remoteURL:     null,
            mimeType:      null,
        },
        {
            name:         'Swift Layouts',
            resourceType: 'Note',
            size:         '',
            content:      'YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGvECILDBUZIScyMzQ1RUtRVmlqcHh5ZHp7f4OHkZmanaWmq6+0VSRudWxs1A0ODxAREhMUWE5TU3RyaW5nXxAPTlNBdHRyaWJ1dGVJbmZvXE5TQXR0cmlidXRlc1YkY2xhc3OAAoAfgASAIdIQFhcYWU5TLnN0cmluZ4ADbxEGlABTAHcAaQBmAHQAVQBJACAATABhAHkAbwB1AHQAcwAKAEIAdQBpAGwAZABpAG4AZwAgAGEAbgBkACAAYQByAHIAYQBuAGcAaQBuAGcAIAB2AGkAZQB3AHMAIABvAG4AIABzAGMAcgBlAGUAbgAKAAoAVgBTAHQAYQBjAGsAICAUACAAdgBlAHIAdABpAGMAYQBsAAoACgBBAHIAcgBhAG4AZwBlAHMAIAB2AGkAZQB3AHMAIAB0AG8AcAAgAHQAbwAgAGIAbwB0AHQAbwBtAC4AIABVAHMAZQAgAHMAcABhAGMAaQBuAGcAIAB0AG8AIABjAG8AbgB0AHIAbwBsACAAdABoAGUAIABnAGEAcAAgAGIAZQB0AHcAZQBlAG4AIABjAGgAaQBsAGQAcgBlAG4ALgAKAHMAdwBpAGYAdABWAFMAdABhAGMAawAoAHMAcABhAGMAaQBuAGcAOgAgADEAMgApACAAewAKACAAIABUAGUAeAB0ACgAIgBIAGUAbABsAG8AIgApAAoAIAAgAFQAZQB4AHQAKAAiAFcAbwByAGwAZAAiACkACgAgACAAQgB1AHQAdABvAG4AKAAiAFQAYQBwACAAbQBlACIAKQAgAHsAIAB9AAoAfQAKAAoASABTAHQAYQBjAGsAICAUACAAaABvAHIAaQB6AG8AbgB0AGEAbAAKAAoAQQByAHIAYQBuAGcAZQBzACAAdgBpAGUAdwBzACAAbABlAGYAdAAgAHQAbwAgAHIAaQBnAGgAdAAuACAAQwBvAG0AYgBpAG4AZQAgAHcAaQB0AGgAIABWAFMAdABhAGMAawAgAHQAbwAgAGIAdQBpAGwAZAAgAGMAbwBtAHAAbABlAHgAIABsAGEAeQBvAHUAdABzAC4ACgBzAHcAaQBmAHQASABTAHQAYQBjAGsAKABzAHAAYQBjAGkAbgBnADoAIAA4ACkAIAB7AAoAIAAgAEkAbQBhAGcAZQAoAHMAeQBzAHQAZQBtAE4AYQBtAGUAOgAgACIAcwB0AGEAcgAiACkACgAgACAAVABlAHgAdAAoACIARgBhAHYAbwB1AHIAaQB0AGUAcwAiACkACgAgACAAUwBwAGEAYwBlAHIAKAApAAoAfQAKAAoAWgBTAHQAYQBjAGsAICAUACAAbABhAHkAZQByAGUAZAAKAAoATwB2AGUAcgBsAGEAeQBzACAAdgBpAGUAdwBzACAAbwBuACAAdABvAHAAIABvAGYAIABlAGEAYwBoACAAbwB0AGgAZQByAC4AIABHAHIAZQBhAHQAIABmAG8AcgAgAGIAYQBkAGcAZQBzACwAIABvAHYAZQByAGwAYQB5AHMALAAgAGEAbgBkACAAYgBhAGMAawBnAHIAbwB1AG4AZAAgAGkAbQBhAGcAZQBzAC4ACgBzAHcAaQBmAHQAWgBTAHQAYQBjAGsAIAB7AAoAIAAgAEMAbwBsAG8AcgAuAGIAbAB1AGUACgAgACAAVABlAHgAdAAoACIATwBuACAAdABvAHAAIgApAAoAIAAgACAAIAAuAGYAbwByAGUAZwByAG8AdQBuAGQAQwBvAGwAbwByACgALgB3AGgAaQB0AGUAKQAKACAAIAAgACAALgBmAG8AbgB0ACgALgB0AGkAdABsAGUAKQAKAH0ACgAKAFMAcABhAGMAZQByACAAJgAgAFAAYQBkAGQAaQBuAGcAICAUACAAcwBwAGEAYwBpAG4AZwAKAAoAUwBwAGEAYwBlAHIAIABmAGkAbABsAHMAIABhAHYAYQBpAGwAYQBiAGwAZQAgAHMAcABhAGMAZQAgAHQAbwAgAHAAdQBzAGgAIAB2AGkAZQB3AHMAIABhAHAAYQByAHQALgAgAC4AcABhAGQAZABpAG4AZwAoACkAIABhAGQAZABzACAAaQBuAHQAZQByAG4AYQBsACAAYgByAGUAYQB0AGgAaQBuAGcAIAByAG8AbwBtAC4ACgBzAHcAaQBmAHQASABTAHQAYQBjAGsAIAB7AAoAIAAgAFQAZQB4AHQAKAAiAEwAZQBmAHQAIgApAAoAIAAgAFMAcABhAGMAZQByACgAKQAKACAAIABUAGUAeAB0ACgAIgBSAGkAZwBoAHQAIgApAAoAfQAKAC4AcABhAGQAZABpAG4AZwAoADEANgApAAoACgBTAGMAcgBvAGwAbABWAGkAZQB3ACAgFAAgAHMAYwByAG8AbABsAGEAYgBsAGUACgAKAFcAcgBhAHAAcwAgAGMAbwBuAHQAZQBuAHQAIAB0AGgAYQB0ACAAbQBhAHkAIABvAHYAZQByAGYAbABvAHcAIAB0AGgAZQAgAHMAYwByAGUAZQBuAC4AIABXAG8AcgBrAHMAIAB2AGUAcgB0AGkAYwBhAGwAbAB5ACAAbwByACAAaABvAHIAaQB6AG8AbgB0AGEAbABsAHkALgAKAHMAdwBpAGYAdABTAGMAcgBvAGwAbABWAGkAZQB3ACAAewAKACAAIABWAFMAdABhAGMAawAgAHsACgAgACAAIAAgAEYAbwByAEUAYQBjAGgAKAAwAC4ALgA8ADIAMAApACAAewAgAGkAIABpAG4ACgAgACAAIAAgACAAIABUAGUAeAB0ACgAIgBJAHQAZQBtACAAXAAoAGkAKQAiACkACgAgACAAIAAgAH0ACgAgACAAfQAKAH0ACgAKAEwAaQBzAHQAICAUACAAdABhAGIAbABlACAAdgBpAGUAdwAKAAoAUwB3AGkAZgB0AFUASQAnAHMAIABiAHUAaQBsAHQALQBpAG4AIAB0AGEAYgBsAGUAIAB2AGkAZQB3AC4AIABIAGEAbgBkAGwAZQBzACAAcwBjAHIAbwBsAGwAaQBuAGcALAAgAHMAZQBwAGEAcgBhAHQAbwByAHMALAAgAGEAbgBkACAAbgBhAHYAaQBnAGEAdABpAG8AbgAgAGEAdQB0AG8AbQBhAHQAaQBjAGEAbABsAHkALgAKAHMAdwBpAGYAdABMAGkAcwB0ACgAaQB0AGUAbQBzACkAIAB7ACAAaQB0AGUAbQAgAGkAbgAKACAAIABIAFMAdABhAGMAawAgAHsACgAgACAAIAAgAFQAZQB4AHQAKABpAHQAZQBtAC4AbgBhAG0AZQApAAoAIAAgACAAIABTAHAAYQBjAGUAcgAoACkACgAgACAAIAAgAFQAZQB4AHQAKABpAHQAZQBtAC4AcAByAGkAYwBlACkACgAgACAAfQAKAH0ACgAKAGYAcgBhAG0AZQAgAG0AbwBkAGkAZgBpAGUAcgAgIBQAIABzAGkAegBpAG4AZwAKAAoAQwBvAG4AdAByAG8AbABzACAAYQAgAHYAaQBlAHcAJwBzACAAcwBpAHoAZQAuACAAVQBzAGUAIABtAGEAeABXAGkAZAB0AGgAOgAgAC4AaQBuAGYAaQBuAGkAdAB5ACAAdABvACAAcwB0AHIAZQB0AGMAaAAgAGEAIAB2AGkAZQB3ACAAdABvACAAZgBpAGwAbAAgAGkAdABzACAAYwBvAG4AdABhAGkAbgBlAHIALgAKAHMAdwBpAGYAdABUAGUAeAB0ACgAIgBGAHUAbABsACAAdwBpAGQAdABoACIAKQAKACAAIAAuAGYAcgBhAG0AZQAoAG0AYQB4AFcAaQBkAHQAaAA6ACAALgBpAG4AZgBpAG4AaQB0AHkALAAgAGgAZQBpAGcAaAB0ADoAIAA1ADAAKQAKACAAIAAuAGIAYQBjAGsAZwByAG8AdQBuAGQAKABDAG8AbABvAHIALgBiAGwAdQBlACkACgAKAEwAYQB6AHkAVgBHAHIAaQBkACAgFAAgAGcAcgBpAGQACgAKAEMAcgBlAGEAdABlAHMAIAByAGUAcwBwAG8AbgBzAGkAdgBlACAAZwByAGkAZAAgAGwAYQB5AG8AdQB0AHMALgAgAEQAZQBmAGkAbgBlACAAYwBvAGwAdQBtAG4AcwAgAHcAaQB0AGgAIABHAHIAaQBkAEkAdABlAG0AICAUACAAdQBzAGUAIAAuAGYAbABlAHgAaQBiAGwAZQAoACkAIABmAG8AcgAgAGUAcQB1AGEAbAAgAHcAaQBkAHQAaABzAC4ACgBzAHcAaQBmAHQAbABlAHQAIABjAG8AbABzACAAPQAgAFsARwByAGkAZABJAHQAZQBtACgALgBmAGwAZQB4AGkAYgBsAGUAKAApACkALAAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgAEcAcgBpAGQASQB0AGUAbQAoAC4AZgBsAGUAeABpAGIAbABlACgAKQApAF0ACgAKAEwAYQB6AHkAVgBHAHIAaQBkACgAYwBvAGwAdQBtAG4AcwA6ACAAYwBvAGwAcwApACAAewAKACAAIABGAG8AcgBFAGEAYwBoACgAaQB0AGUAbQBzACkAIAB7ACAAVABlAHgAdAAoACQAMAAuAG4AYQBtAGUAKQAgAH0ACgB90hobHB1aJGNsYXNzbmFtZVgkY2xhc3Nlc18QD05TTXV0YWJsZVN0cmluZ6MeHyBfEA9OU011dGFibGVTdHJpbmdYTlNTdHJpbmdYTlNPYmplY3TSIhAjJlpOUy5vYmplY3RzoiQlgAWAGIAe0ygiECktMVdOUy5rZXlzoyorLIAGgAeACKMuLzCACYALgA2AFVdOU0NvbG9yXxAQTlNQYXJhZ3JhcGhTdHlsZVZOU0ZvbnTYNjc4OToQOzw9Pj9AQUJDRF8QFVVJQ29sb3JDb21wb25lbnRDb3VudFdVSUdyZWVuVlVJQmx1ZVdVSUFscGhhVU5TUkdCVVVJUmVkXE5TQ29sb3JTcGFjZRAEIj9l5eYiP2Tk5SI/gAAATxARMC45MDYgMC44OTggMC44OTSACiI/Z+foEALTGhtGR0hJWyRjbGFzc2hpbnRzV1VJQ29sb3KiRyChSldOU0NvbG9y00wQTU5PUFpOU1RhYlN0b3BzW05TQWxpZ25tZW50gACADBAE0hobUlNfEBdOU011dGFibGVQYXJhZ3JhcGhTdHlsZaNUVSBfEBdOU011dGFibGVQYXJhZ3JhcGhTdHlsZV8QEE5TUGFyYWdyYXBoU3R5bGXbV1hZWlsQXF1eX2BhYWJjZGVEZE5jaF8QIlVJRm9udE1heGltdW1Qb2ludFNpemVBZnRlclNjYWxpbmdfEBlVSUZvbnRQb2ludFNpemVGb3JTY2FsaW5nXxAQVUlGb250RGVzY3JpcHRvclZOU05hbWVWTlNTaXplXFVJRm9udFRyYWl0c18QD1VJRm9udFBvaW50U2l6ZV8QGVVJRm9udFRleHRTdHlsZUZvclNjYWxpbmdaVUlGb250TmFtZVxVSVN5c3RlbUZvbnQjAAAAAAAAAACAD4AOI0AwAAAAAAAAgBeAAIAOCV4uU0ZVSS1TZW1pYm9sZNNrEGxtbm9fEBdVSUZvbnREZXNjcmlwdG9yT3B0aW9uc18QGlVJRm9udERlc2NyaXB0b3JBdHRyaWJ1dGVzEoAAhASAFoAQ0ygiEHF0MaJyc4ARgBKidXaAE4AUgBVfEBNOU0ZvbnRTaXplQXR0cmlidXRlXxAYTlNDVEZvbnRVSVVzYWdlQXR0cmlidXRlXxAVQ1RGb250RW1waGFzaXplZFVzYWdl0hobfH1cTlNEaWN0aW9uYXJ5on4gXE5TRGljdGlvbmFyedIaG4CBXxAQVUlGb250RGVzY3JpcHRvcqKCIF8QEFVJRm9udERlc2NyaXB0b3LTGhtGhIWGVlVJRm9udKKEIKE00ygiEIiMMaMqKyyABoAHgAijLi+PgAmAC4AZgBXbV1hZWlsQXF1eX2BhYZKTZGWVZE6TaIAbgBqAFxAAgACAGgldLlNGVUktUmVndWxhctNrEGxtbpyAFoAc0ygiEJ6hMaJyc4ARgBKidaOAE4AdgBVfEBJDVEZvbnRSZWd1bGFyVXNhZ2XSGhunqF5OU011dGFibGVBcnJheaOpqiBeTlNNdXRhYmxlQXJyYXlXTlNBcnJhedKsEK2uV05TLmRhdGFPECwPACkBEQCmAQETAKcBARAAuAEBGgClAQEXAK0BAREAwQEBFwC4AQEQAO8BAYAg0hobsLFdTlNNdXRhYmxlRGF0YaOysyBdTlNNdXRhYmxlRGF0YVZOU0RhdGHSGhu1tl8QEk5TQXR0cmlidXRlZFN0cmluZ6K3IF8QEk5TQXR0cmlidXRlZFN0cmluZwAIABEAGgAkACkAMgA3AEkATABRAFMAeAB+AIcAkACiAK8AtgC4ALoAvAC+AMMAzQDPDfsOAA4LDhQOJg4qDjwORQ5ODlMOXg5hDmMOZQ5nDm4Odg56DnwOfg6ADoQOhg6IDooOjA6UDqcOrg6/DtcO3w7mDu4O9A76DwcPCQ8ODxMPGA8sDy4PMw81DzwPSA9QD1MPVQ9dD2QPbw97D30Pfw+BD4YPoA+kD74P0Q/oEA0QKRA8EEMQShBXEGkQhRCQEJ0QphCoEKoQsxC1ELcQuRC6EMkQ0BDqEQcRDBEOERARFxEaERwRHhEhESMRJREnET0RWBFwEXURghGFEZIRlxGqEa0RwBHHEc4R0RHTEdoR3hHgEeIR5BHoEeoR7BHuEfASBxIJEgsSDRIPEhESExIUEiISKRIrEi0SNBI3EjkSOxI+EkASQhJEElkSXhJtEnESgBKIEo0SlRLEEsYSyxLZEt0S6xLyEvcTDBMPAAAAAAAAAgEAAAAAAAAAuAAAAAAAAAAAAAAAAAAAEyQ=',
            localFilePath: null,
            remoteURL:     null,
            mimeType:      null,
        },
        {
            name:         'Architecture of iOS',
            resourceType: 'Link',
            size:         '',
            content:      null,
            localFilePath: null,
            remoteURL:    'https://www.geeksforgeeks.org/operating-systems/architecture-of-ios-operating-system/',
            mimeType:     null,
        },
    ]

    const newResourceIds = []

    for (const def of resourceDefs) {
        const existing = await db.collection('resources')
            .where('subjectId', '==', iosId)
            .where('name',      '==', def.name)
            .limit(1)
            .get()

        if (!existing.empty) {
            console.log(`Resource "${def.name}" already exists — skipping`)
            continue
        }

        const resourceId = db.collection('resources').doc().id
        const doc = {
            id:           resourceId,
            userId:       uid,
            subjectId:    iosId,
            name:         def.name,
            resourceType: def.resourceType,
            size:         def.size,
            tags:         [],
            isFavorite:   false,
            syncStatus:   'synced',
            createdAt:    ts(new Date('2026-05-01T00:00:00Z')),
            updatedAt:    ts(new Date('2026-05-01T00:00:00Z')),
        }
        if (def.content       !== null) doc.content       = def.content
        if (def.localFilePath !== null) doc.localFilePath = def.localFilePath
        if (def.remoteURL     !== null) doc.remoteURL     = def.remoteURL
        if (def.mimeType      !== null) doc.mimeType      = def.mimeType

        await db.collection('resources').doc(resourceId).set(doc)
        newResourceIds.push(resourceId)
        console.log(`Resource "${def.name}" created ✅`)
    }

    if (newResourceIds.length > 0) {
        const currentSubject = await db.collection('subjects').doc(iosId).get()
        const existingResourceIds = currentSubject.data().resourceIds || []
        const allResourceIds = [...new Set([...existingResourceIds, ...newResourceIds])]
        await db.collection('subjects').doc(iosId).update({
            resourceIds:   allResourceIds,
            resourceCount: allResourceIds.length,
            updatedAt:     ts(new Date()),
        })
        console.log(`iOS subject resourceIds updated (${allResourceIds.length} total) ✅`)
    }

    // ── Resources (Web Application) ────────────────────────────────────────────
    const webId = subjectIds['Web Application']

    const webResourceDefs = [
        {
            name:         'What is an API',
            resourceType: 'Recording',
            size:         '00:45',
            content:      '[{"timestamp":1.6175799369812012,"text":"What","duration":0,"id":"F31E30AB-B0AB-461D-9ED5-5501AEDC2A30"},{"id":"2AE50D6E-870A-4648-B7EC-E75C72B9CEF2","text":"is","timestamp":1.849942922592163,"duration":0},{"id":"2276EE19-41DC-4D02-A628-BDEA52A1570E","text":"an","timestamp":2.114414930343628,"duration":0},{"id":"51CE4A87-4CE5-47DA-A669-8A6432638D66","text":"API","timestamp":2.414583921432495,"duration":0},{"id":"CAD202CE-AF63-4571-A422-95EA6D7DB72D","text":"API","timestamp":3.0436019897460938,"duration":0},{"text":"stands","timestamp":3.645405888557434,"id":"A68E7694-61A4-4583-8C7D-63C6B6A9C2E4","duration":0},{"text":"for","timestamp":3.833319902420044,"id":"284E46DE-9BD5-4447-AF3E-446DE11ED5FE","duration":0},{"text":"application","timestamp":4.2262609004974365,"id":"C9216AC6-919C-45BF-A705-93FCEE077BF4","duration":0},{"text":"programming","timestamp":4.8310699462890625,"id":"F2394D5B-E0B9-456C-8D3E-D73E277E975A","duration":0},{"text":"interface","timestamp":5.216913938522339,"id":"13B21747-5076-413F-BA92-695D4599073F","duration":0},{"text":"in","timestamp":5.7666929960250854,"id":"339A80C0-7A09-44AE-95B1-3B2EC413048D","duration":0},{"text":"the","timestamp":5.787851929664612,"id":"C89BF3B2-5670-4C68-9A76-8F34B4CDBEFE","duration":0},{"text":"most","timestamp":6.060115933418274,"id":"0E66FCCA-D111-4DDF-8C05-CCB7E887BFAC","duration":0},{"text":"simple","timestamp":6.234632968902588,"id":"618D6B84-9A62-450B-AB85-754CFB19366E","duration":0},{"text":"way","timestamp":6.625541925430298,"id":"5B574EED-A25C-4E8C-9060-8F1C54379D1F","duration":0},{"text":"in","timestamp":6.950695991516113,"id":"C62E238A-5D00-4801-92DA-80DDCA6AF952","duration":0},{"text":"API","timestamp":7.2505539655685425,"id":"ADEF79D0-3649-4821-A34D-0A9BE3CAEA2C","duration":0},{"text":"is","timestamp":7.654170989990234,"id":"FCF2F9ED-021A-47C5-A6BB-78A07B80A2E7","duration":0},{"text":"basically","timestamp":7.675327897071838,"id":"41718F27-B03F-4B43-82B6-F53E8B54B597","duration":0},{"text":"a","timestamp":8.153532981872559,"id":"D8B0E175-49F2-44A5-9773-BCEFD891DB0E","duration":0},{"text":"list","timestamp":8.422871947288513,"id":"31B6823A-2ABE-412F-9592-8E523BF55B59","duration":0},{"text":"of","timestamp":8.628077983856201,"id":"6919F519-010F-4DE3-A492-32DC135FF6DB","duration":0},{"text":"operations","timestamp":9.02465295791626,"id":"469D3A91-D754-4B5A-BBB6-C47F26E97B08","duration":0},{"text":"with","timestamp":9.664391994476318,"id":"D06C3D46-3572-440B-BE13-1104CCDEDF2F","duration":0},{"text":"a","timestamp":9.704238891601562,"id":"9B2AC5E0-CCB9-44E4-A883-A00EA82B25EF","duration":0},{"id":"12DD9636-E0BE-4434-92FE-8051C4BB30F6","timestamp":9.80746591091156,"text":"description","duration":0},{"id":"5AA35DE5-16DF-4767-A379-F530AD03B4B8","timestamp":10.261343002319336,"text":"of","duration":0},{"id":"2DA0A51E-C3DA-45BE-873F-481A8CD6A5D0","timestamp":10.838615894317627,"text":"what","duration":0},{"id":"AC2FF72C-A847-49A0-9128-7C90932F354B","timestamp":11.04085397720337,"text":"exactly","duration":0},{"id":"077C9B4A-FCF0-47F0-A77B-88D2B8B31D6A","timestamp":11.229825973510742,"text":"they","duration":0},{"id":"F7B32AC6-4A7D-4448-96F8-3044CD4C0941","timestamp":11.441219925880432,"text":"do","duration":0},{"id":"C2341C86-8E3D-4732-9952-62F78203F4DD","timestamp":11.746293902397156,"text":"and","duration":0},{"id":"101E44E0-E843-41F9-9BBF-4AC34E5E048C","timestamp":12.23526394367218,"text":"developers","duration":0},{"id":"612DE707-1955-46CC-950F-34057F2DC9D5","timestamp":12.653284907341003,"text":"use","duration":0},{"id":"E55B5E5C-A7F8-489E-AEF5-0AE17CC0C386","timestamp":12.653284907341003,"text":"them","duration":0},{"id":"35E8A83F-4570-47A6-8FF7-1A0694520107","timestamp":12.978867888450623,"text":"in","duration":0},{"id":"DADF394E-A251-4191-878E-D0ECA6089615","timestamp":13.315039992332458,"text":"their","duration":0},{"id":"8A475D15-CD09-43BB-9D3F-6A363F225EAB","timestamp":13.661195993423462,"text":"coat","duration":0},{"id":"9D5E1CFE-C47C-4B47-A17C-3F42E2FBD8B7","timestamp":14.176208972930908,"text":"perform","duration":0},{"id":"4075A424-4FAB-4028-B82E-FBE2233F8B56","timestamp":14.669495940208435,"text":"certain","duration":0},{"duration":0,"id":"F1C02664-BCAD-48C7-85AD-CEB39130EC06","text":"actions","timestamp":14.845924973487854},{"duration":0,"id":"93FEB041-FFE7-48AF-BF71-8E2C987AAC50","text":"an","timestamp":15.858133912086487},{"duration":0,"id":"E30097C6-41EF-42FB-9150-7FE81766176A","text":"example","timestamp":15.883433938026428},{"duration":0,"id":"33844C92-12AC-4021-B107-0D8F60799084","text":"when","timestamp":16.265082955360413},{"duration":0,"id":"3FDE3B44-4FD1-424E-B8B3-5A002C93C482","text":"you","timestamp":16.265082955360413},{"duration":0,"id":"82708DFD-D26C-4318-86DE-46D65355B642","text":"like","timestamp":16.562673926353455},{"duration":0,"id":"DAB391E0-665D-44FC-9C51-735595ABE043","text":"a","timestamp":17.034507989883423},{"duration":0,"id":"BCEBA58D-0EA6-420B-8CA4-65166550ED63","text":"video","timestamp":17.034507989883423},{"duration":0,"id":"26D9E4FB-C29E-4DDE-AC81-C9A5EC597427","text":"on","timestamp":17.25348997116089},{"duration":0,"id":"9F01AD54-58E6-4035-B306-B644B3DEDFA7","text":"TikTok","timestamp":17.745810985565186},{"duration":0,"id":"D6CD1C68-7FBA-4476-AE3B-C93841B8FC02","text":"API","timestamp":18.25685489177704},{"duration":0,"id":"19E75659-C34F-4BAE-80A7-087B59B10DC6","text":"it\'ll","timestamp":18.25685489177704},{"duration":0,"id":"86C4B119-B156-434C-BA98-E529A88F2777","text":"trigger","timestamp":19.64787197113037},{"duration":0,"id":"6436F78C-26FC-43C3-B2C9-13B8467D4E37","text":"the","timestamp":20.458783984184265},{"duration":0,"id":"24820BE3-157D-43FE-9DD9-56DA4BD5136C","text":"function","timestamp":20.857340931892395},{"duration":0,"id":"4056B822-5331-4407-8937-973E2407690A","text":"the","timestamp":21.866639971733093},{"duration":0,"id":"C0E4AEA3-BE22-4970-B918-744757EA98F8","text":"function","timestamp":21.866639971733093},{"duration":0,"id":"DA9C30D4-DDB1-4293-B8D2-EC7BFDC435EE","text":"will","timestamp":22.27288591861725},{"duration":0,"id":"65311302-C9E8-420E-902D-C1028E5AE1D8","text":"ideally","timestamp":22.28434991836548},{"duration":0,"id":"EAD569DF-F0E3-487F-AC6E-6421FB656E6A","text":"user","timestamp":22.87370193004608},{"duration":0,"id":"ECDC22E4-5420-4EDF-8590-E3A758230FC5","text":"the","timestamp":23.271477937698364},{"duration":0,"id":"5AE41420-DAFB-42A3-83E9-4ABE8A246588","text":"idea","timestamp":23.271477937698364},{"duration":0,"id":"C67CCF4D-AA9C-4297-863D-DFBF4E7ED1F1","text":"of","timestamp":24.437066912651062},{"duration":0,"id":"25FFF090-0A9E-4833-9217-1BA939DC957F","text":"the","timestamp":24.642347931861877},{"duration":0,"id":"D0B20B37-4A54-44B2-95C2-67289F5DEEBC","text":"content","timestamp":24.955034971237183},{"duration":0,"id":"524689A4-A891-4118-8BAE-39C75D183A36","text":"and","timestamp":25.231152892112732},{"duration":0,"id":"EB817A9C-EDF8-4EA4-8F1F-CBF828BF9F8E","text":"when","timestamp":25.65744400024414},{"duration":0,"id":"75A7389D-1823-4559-90C3-8251855FC00C","text":"the","timestamp":25.674508929252625},{"duration":0,"id":"98709ACF-33EA-4828-891B-0A39005B24B8","text":"video","timestamp":26.146483898162842},{"duration":0,"id":"DB16890D-2D9E-4EEB-9D19-56FD7EAE7E4F","text":"was","timestamp":26.4206759929657},{"duration":0,"id":"380D67FF-8963-4EB6-9426-F4B9EFC9DA06","text":"like","timestamp":26.603769898414612},{"duration":0,"id":"91D78989-ACAE-49FF-B142-A5863A3D4D1D","text":"and","timestamp":27.085667967796326},{"duration":0,"id":"42F71912-43A9-4329-BCC5-C6ED3AE14FE2","text":"then","timestamp":27.085667967796326},{"duration":0,"id":"E21966DA-E3DD-4F84-BF61-4F35F5CDD300","text":"takes","timestamp":27.36153495311737},{"duration":0,"id":"F311F77A-6A54-4AEF-9A1A-9912B9B14591","text":"all","timestamp":27.684574961662292},{"duration":0,"id":"6BAAF9AE-FA77-4D1F-9211-51C5BB2FE024","text":"these","timestamp":27.75594389438629},{"duration":0,"timestamp":27.860630989074707,"text":"input","id":"0AB0DBE7-42DB-4531-95D0-17E5B53AED3F"},{"duration":0,"timestamp":28.270107984542847,"text":"and","id":"2B88D9FD-A1E1-4694-83C6-5866DC56F735"},{"duration":0,"timestamp":28.564063906669617,"text":"perform","id":"201F454C-08DE-49F4-988A-531E37E7B5E0"},{"duration":0,"timestamp":29.047334909439087,"text":"all","id":"B2627309-2F44-4BC4-947F-290717E2CE98"},{"duration":0,"timestamp":29.079824924468994,"text":"the","id":"BFA90660-0D70-4EF3-AE63-0364945206FF"},{"duration":0,"timestamp":29.76170289516449,"text":"necessary","id":"2B51CAB5-40AC-4C96-AF88-F49788CD4D1F"},{"duration":0,"timestamp":29.76170289516449,"text":"updates","id":"1BEABDCA-2149-4B1B-9942-35152DEDBA2E"},{"duration":0,"timestamp":30.083614945411682,"text":"in","id":"86839747-0513-428F-8442-328840E7C5FB"},{"duration":0,"timestamp":30.108552932739258,"text":"the","id":"09DEECA2-C953-402C-ABAB-8436A5DBAAED"},{"duration":0,"timestamp":30.264739990234375,"text":"background","id":"58A2C790-8C7D-435B-B008-86415CC7E872"},{"duration":0,"timestamp":30.696592926979065,"text":"such","id":"EC740ACD-B375-438A-9CAA-5EE440645001"},{"duration":0,"timestamp":30.804330945014954,"text":"as","id":"65EF5163-2455-4C8C-857C-932F8B4DFC4C"},{"duration":0,"timestamp":31.30693292617798,"text":"updating","id":"4C438BA3-171B-40E5-964C-7FA7BDD0C7EA"},{"duration":0,"timestamp":31.444703936576843,"text":"all","id":"3BA5C961-FCC0-42AC-BA29-1BC432F93169"},{"duration":0,"timestamp":31.461671948432922,"text":"the","id":"A209FCE1-EA60-4EFA-87C2-248B91562084"},{"duration":0,"timestamp":32.17208695411682,"text":"necessary","id":"732C5BE3-9592-408E-907E-8A0CE75CDF42"},{"duration":0,"timestamp":32.49937689304352,"text":"daily","id":"91E1AF8A-B66D-442A-B3D5-A6B12E7E354E"},{"duration":0,"timestamp":32.63655197620392,"text":"basis","id":"97BF179B-EA74-4683-B3E4-E8768221C3DB"},{"duration":0,"timestamp":32.86438989639282,"text":"and","id":"311CBE2F-977D-474B-AF43-E79810FFDDBD"},{"duration":0,"timestamp":33.03797495365143,"text":"then","id":"4446C08C-5166-4141-AE7E-BDE3A647E817"},{"duration":0,"timestamp":33.36288094520569,"text":"once","id":"6B5EF76E-539F-4DD9-B9B0-AF7D33BEEFF7"},{"duration":0,"timestamp":33.63612389564514,"text":"that\'s","id":"E115BD10-3BD1-4511-A442-6327FB0CEB31"},{"duration":0,"timestamp":33.839388966560364,"text":"all","id":"DAD9B8D6-0B24-4422-8DC8-7250104D2FD0"},{"duration":0,"timestamp":34.0526819229126,"text":"done","id":"D1106930-41B3-461E-AEEF-30305EF793D0"},{"duration":0,"timestamp":34.236127972602844,"text":"it\'ll","id":"9D030CD6-F9B9-4B5B-862A-6C1EB9D0612F"},{"duration":0,"timestamp":34.24825990200043,"text":"send","id":"9E5CAAC1-E482-413A-9016-C250B8A9919B"},{"duration":0,"timestamp":34.85269296169281,"text":"some","id":"329EAAD8-2A9C-43C3-85D1-12DF0E26CEF7"},{"duration":0,"timestamp":35.02729392051697,"text":"type","id":"2B083191-B1CA-4169-99A9-C6D478D6A05A"},{"duration":0,"timestamp":35.24224591255188,"text":"of","id":"4C2BEE1A-30D4-4A25-863A-5E64D4380D3A"},{"duration":0,"timestamp":35.44952893257141,"text":"success","id":"BE61FFC3-B88A-4FE4-99DB-5321E4C88C09"},{"duration":0,"timestamp":36.04161095619202,"text":"response","id":"917FD760-771F-46DE-9776-BA6D30327FD1"},{"duration":0,"timestamp":36.24329698085785,"text":"back","id":"970AAD41-7B0A-4583-813C-B27E0379F56C"},{"duration":0,"timestamp":36.43019092082977,"text":"to","id":"FE4DEF3A-6F1F-4F93-BB48-2226C24CBEE0"},{"duration":0,"timestamp":36.44198799133301,"text":"the","id":"BB25B64B-7A20-4D35-9B01-43FD413B8872"},{"duration":0,"timestamp":36.95787489414215,"text":"TikTok","id":"4CFFCF0F-5F1F-43F0-9781-BF14095E0FD7"},{"duration":0,"timestamp":37.25701189041138,"text":"app","id":"DFB844C9-19E7-4CB2-BA9A-1E4DFAFDF348"},{"text":"successfully","duration":0,"id":"2EA7E8C8-BADF-4929-9383-FDD0F927BBBC","timestamp":37.64940297603607},{"text":"like","duration":0,"id":"83BEE08A-3A09-4411-B931-D26ACB62E3E9","timestamp":38.14446198940277},{"text":"a","duration":0,"id":"0DE07C02-9FA4-4401-BB46-E9ED991A2070","timestamp":38.446637988090515},{"text":"post","duration":0,"id":"2694054C-E706-44DB-B25B-2693DB0EF5FA","timestamp":38.646137952804565},{"text":"don\'t","duration":0,"id":"386FE2B0-86AD-4B0F-B2C8-60FB5F55E212","timestamp":39.37846398353577},{"text":"really","duration":0,"id":"16535FC6-A484-487B-B6F9-E8AF205EA47D","timestamp":39.67356288433075},{"text":"need","duration":0,"id":"86A48CC0-6C6D-4328-947F-DE3ED040C7F6","timestamp":39.83974099159241},{"text":"to","duration":0,"id":"6DAA3F80-CFBF-4B48-9068-56661D9B02D0","timestamp":39.8568229675293},{"text":"focus","duration":0,"id":"290639E7-CD64-45EE-B1DF-4008F7179347","timestamp":40.03457188606262},{"text":"on","duration":0,"id":"2D29F546-4F97-4C23-8482-DFE402CC96C2","timestamp":40.223559975624084},{"text":"what","duration":0,"id":"23940EA2-C96B-4694-BDA8-7E38BC3FFD04","timestamp":40.54029190540314},{"text":"exactly","duration":0,"id":"325770E7-DA70-4C06-9C87-D9120F8CF1F5","timestamp":40.846242904663086},{"text":"the","duration":0,"id":"69D2CED2-DEA1-43E0-AACA-5CE788B5BE6F","timestamp":41.05265390872955},{"text":"API","duration":0,"id":"AA3039F9-50C4-459D-B108-21B3FAD3A4BA","timestamp":41.47226393222809},{"text":"does","duration":0,"id":"795319A3-6684-4F89-BEA1-6A7F0B69D7B9","timestamp":41.50399398803711},{"text":"and","duration":0,"id":"1A29D90A-30D9-47C5-B442-E8ABF7D897CF","timestamp":41.80172097682953},{"text":"they","duration":0,"id":"3FC76F62-00A0-4348-BAE6-E8644DD61275","timestamp":42.329702973365784},{"text":"really","duration":0,"id":"D8CC0B29-19CC-4378-90C0-FBBA20CA3AC1","timestamp":42.38075590133667},{"text":"need","duration":0,"id":"B4F048F6-9A35-49E7-AAFE-5CE7009BCD81","timestamp":42.45197296142578},{"text":"to","duration":0,"id":"C951F08A-0119-4BDA-AB7C-59A8C543ED9E","timestamp":42.639604926109314},{"text":"focus","duration":0,"id":"48BBCE89-D8E4-439C-9F17-508806436D41","timestamp":42.65037393569946},{"text":"on","duration":0,"id":"9B6BA431-2C53-4091-95C6-3942EB875B65","timestamp":43.25218093395233},{"text":"the","duration":0,"id":"DFDACCC4-2497-4E20-8C98-35DBE5D20EDE","timestamp":43.436540961265564},{"text":"input","duration":0,"id":"6DE8D01E-F242-4730-A5F1-CBEC16DCF7C9","timestamp":43.6503369808197},{"text":"of","duration":0,"id":"833C106C-8BA1-4D48-8813-7AE45D25A098","timestamp":44.18597996234894},{"text":"the","duration":0,"id":"CAAABCBA-58D1-4B8C-A308-C734EA610E03","timestamp":44.27041792869568},{"text":"receipts","duration":0,"id":"FA9BA7A4-D44C-443A-945E-ED1C9143886B","timestamp":44.833406925201416},{"text":"and","duration":0,"id":"75D9B765-B3C2-4792-AF71-2F18EF65AFBC","timestamp":45.01538896560669},{"text":"the","duration":0,"id":"35298083-8338-4D7E-A8E3-2BA1B63C285A","timestamp":45.06813597679138},{"text":"output","duration":0,"id":"C2970F1A-58ED-4731-91E8-BAEAAB8D006F","timestamp":45.10121989250183},{"text":"that","duration":0,"id":"B4CA81EA-12F4-4034-A9F5-4673CDB0104D","timestamp":45.39182496070862}]',
            localFilePath: '41C4FD8C-F117-4199-A8A5-3D2A8B26AD28.m4a',
            remoteURL:     null,
            mimeType:      null,
        },
        {
            name:         'web_api_concepts',
            resourceType: 'PDF',
            size:         '0.0 MB',
            content:      null,
            localFilePath: 'B4773C04-4BA6-49CC-A498-E34F0766F563_web_api_concepts.pdf',
            remoteURL:     null,
            mimeType:      'application/pdf',
        },
        {
            name:         'Scanned REST Basics Lec',
            resourceType: 'PDF',
            size:         '2.5 MB',
            content:      null,
            localFilePath: 'Scanned REST Basics Lec - 4F08B7.pdf',
            remoteURL:     null,
            mimeType:      'application/pdf',
        },
    ]

    const newWebResourceIds = []

    for (const def of webResourceDefs) {
        const existing = await db.collection('resources')
            .where('subjectId', '==', webId)
            .where('name',      '==', def.name)
            .limit(1)
            .get()

        if (!existing.empty) {
            console.log(`Resource "${def.name}" already exists — skipping`)
            continue
        }

        const resourceId = db.collection('resources').doc().id
        const doc = {
            id:           resourceId,
            userId:       uid,
            subjectId:    webId,
            name:         def.name,
            resourceType: def.resourceType,
            size:         def.size,
            tags:         [],
            isFavorite:   false,
            syncStatus:   'synced',
            createdAt:    ts(new Date('2026-05-01T00:00:00Z')),
            updatedAt:    ts(new Date('2026-05-01T00:00:00Z')),
        }
        if (def.content       !== null) doc.content       = def.content
        if (def.localFilePath !== null) doc.localFilePath = def.localFilePath
        if (def.remoteURL     !== null) doc.remoteURL     = def.remoteURL
        if (def.mimeType      !== null) doc.mimeType      = def.mimeType

        await db.collection('resources').doc(resourceId).set(doc)
        newWebResourceIds.push(resourceId)
        console.log(`Resource "${def.name}" created ✅`)
    }

    if (newWebResourceIds.length > 0) {
        const currentWeb = await db.collection('subjects').doc(webId).get()
        const existingWebResourceIds = currentWeb.data().resourceIds || []
        const allWebResourceIds = [...new Set([...existingWebResourceIds, ...newWebResourceIds])]
        await db.collection('subjects').doc(webId).update({
            resourceIds:   allWebResourceIds,
            resourceCount: allWebResourceIds.length,
            updatedAt:     ts(new Date()),
        })
        console.log(`Web Application subject resourceIds updated (${allWebResourceIds.length} total) ✅`)
    }

    // ── Resources (Computer Vision) ────────────────────────────────────────────
    const cvId = subjectIds['Computer Vision']

    const cvResourceDefs = [
        {
            name:         'CV Fundamentals',
            resourceType: 'Note',
            size:         '',
            content:      'YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGvEBgLDBMXHyssLS4+REpPY2RqcnNddHV4fIBVJG51bGzTDQ4PEBESWE5TU3RyaW5nViRjbGFzc1xOU0F0dHJpYnV0ZXOAAoAXgATSDhQVFllOUy5zdHJpbmeAA28RDpEAQwBvAG0AcAB1AHQAZQByACAAVgBpAHMAaQBvAG4AIABGAHUAbgBkAGEAbQBlAG4AdABhAGwAcwAKAEMAbwByAGUAIABjAG8AbgBjAGUAcAB0AHMAIABmAG8AcgAgAHUAbgBkAGUAcgBzAHQAYQBuAGQAaQBuAGcAIABhAG4AZAAgAHAAcgBvAGMAZQBzAHMAaQBuAGcAIAB2AGkAcwB1AGEAbAAgAGQAYQB0AGEACgAKAEkAbQBhAGcAZQBzACAAYQBzACAAQQByAHIAYQB5AHMAICAUACAAcgBlAHAAcgBlAHMAZQBuAHQAYQB0AGkAbwBuAAoARQB2AGUAcgB5ACAAaQBtAGEAZwBlACAAaQBzACAAagB1AHMAdAAgAGEAIABnAHIAaQBkACAAbwBmACAAbgB1AG0AYgBlAHIAcwAuACAARwByAGEAeQBzAGMAYQBsAGUAIABpAG0AYQBnAGUAcwAgAGEAcgBlACAAMgBEACAAYQByAHIAYQB5AHMAOwAgAGMAbwBsAG8AcgAgAGkAbQBhAGcAZQBzACAAYQByAGUAIAAzAEQAIABhAHIAcgBhAHkAcwAgAHcAaQB0AGgAIABoAGUAaQBnAGgAdAAsACAAdwBpAGQAdABoACwAIABhAG4AZAAgADMAIABjAGgAYQBuAG4AZQBsAHMAIAAoAFIALAAgAEcALAAgAEIAKQAuACAAVQBuAGQAZQByAHMAdABhAG4AZABpAG4AZwAgAHQAaABpAHMAIABpAHMAIAB0AGgAZQAgAGYAbwB1AG4AZABhAHQAaQBvAG4AIABvAGYAIABhAGwAbAAgAEMAVgAgAHcAbwByAGsALgAKAHAAeQB0AGgAbwBuAGkAbQBwAG8AcgB0ACAAYwB2ADIACgBpAG0AcABvAHIAdAAgAG4AdQBtAHAAeQAgAGEAcwAgAG4AcAAKAAoAaQBtAGcAIAA9ACAAYwB2ADIALgBpAG0AcgBlAGEAZAAoACIAcABoAG8AdABvAC4AagBwAGcAIgApAAoAcAByAGkAbgB0ACgAaQBtAGcALgBzAGgAYQBwAGUAKQAgACAAIwAgACgAaABlAGkAZwBoAHQALAAgAHcAaQBkAHQAaAAsACAAMwApAAoAcAByAGkAbgB0ACgAaQBtAGcAWwAwACwAIAAwAF0AKQAgACAAIwAgAHAAaQB4AGUAbAAgAGEAdAAgAHQAbwBwAC0AbABlAGYAdAAgIZIAIABbAFIALAAgAEcALAAgAEIAXQAKAAoAQwBvAGwAbwByACAAUwBwAGEAYwBlAHMAICAUACAAQgBHAFIAIAAvACAAUgBHAEIAIAAvACAASABTAFYAIAAvACAARwByAGEAeQBzAGMAYQBsAGUACgBPAHAAZQBuAEMAVgAgAGwAbwBhAGQAcwAgAGkAbQBhAGcAZQBzACAAaQBuACAAQgBHAFIAIABiAHkAIABkAGUAZgBhAHUAbAB0ACwAIABuAG8AdAAgAFIARwBCAC4AIABDAG8AbgB2AGUAcgB0AGkAbgBnACAAYgBlAHQAdwBlAGUAbgAgAGMAbwBsAG8AcgAgAHMAcABhAGMAZQBzACAAaQBzACAAZQBzAHMAZQBuAHQAaQBhAGwAIABmAG8AcgAgAHQAYQBzAGsAcwAgAGwAaQBrAGUAIABzAGsAaQBuACAAZABlAHQAZQBjAHQAaQBvAG4ALAAgAHQAaAByAGUAcwBoAG8AbABkAGkAbgBnACwAIABhAG4AZAAgAHMAZQBnAG0AZQBuAHQAYQB0AGkAbwBuAC4ACgBwAHkAdABoAG8AbgBnAHIAYQB5ACAAPQAgAGMAdgAyAC4AYwB2AHQAQwBvAGwAbwByACgAaQBtAGcALAAgAGMAdgAyAC4AQwBPAEwATwBSAF8AQgBHAFIAMgBHAFIAQQBZACkACgBoAHMAdgAgACAAPQAgAGMAdgAyAC4AYwB2AHQAQwBvAGwAbwByACgAaQBtAGcALAAgAGMAdgAyAC4AQwBPAEwATwBSAF8AQgBHAFIAMgBIAFMAVgApAAoAcgBnAGIAIAAgAD0AIABjAHYAMgAuAGMAdgB0AEMAbwBsAG8AcgAoAGkAbQBnACwAIABjAHYAMgAuAEMATwBMAE8AUgBfAEIARwBSADIAUgBHAEIAKQAKAAoAVABoAHIAZQBzAGgAbwBsAGQAaQBuAGcAICAUACAAcwBlAGcAbQBlAG4AdABhAHQAaQBvAG4ACgBDAG8AbgB2AGUAcgB0AHMAIABhACAAZwByAGEAeQBzAGMAYQBsAGUAIABpAG0AYQBnAGUAIAB0AG8AIABiAGkAbgBhAHIAeQAgACgAYgBsAGEAYwBrACAAJgAgAHcAaABpAHQAZQApACAAYgB5ACAAcwBlAHQAdABpAG4AZwAgAHAAaQB4AGUAbABzACAAYQBiAG8AdgBlACAAYQAgAHYAYQBsAHUAZQAgAHQAbwAgAHcAaABpAHQAZQAgAGEAbgBkACAAYgBlAGwAbwB3ACAAdABvACAAYgBsAGEAYwBrAC4AIABVAHMAZQBkACAAdABvACAAaQBzAG8AbABhAHQAZQAgAG8AYgBqAGUAYwB0AHMAIABmAHIAbwBtACAAYgBhAGMAawBnAHIAbwB1AG4AZABzAC4ACgBwAHkAdABoAG8AbgBfACwAIAB0AGgAcgBlAHMAaAAgAD0AIABjAHYAMgAuAHQAaAByAGUAcwBoAG8AbABkACgAZwByAGEAeQAsACAAMQAyADcALAAgADIANQA1ACwACgAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAYwB2ADIALgBUAEgAUgBFAFMASABfAEIASQBOAEEAUgBZACkACgAKACMAIABhAGQAYQBwAHQAaQB2AGUAIABmAG8AcgAgAHUAbgBlAHYAZQBuACAAbABpAGcAaAB0AGkAbgBnAAoAdABoAHIAZQBzAGgAIAA9ACAAYwB2ADIALgBhAGQAYQBwAHQAaQB2AGUAVABoAHIAZQBzAGgAbwBsAGQAKABnAHIAYQB5ACwAIAAyADUANQAsAAoAIAAgACAAIAAgACAAIAAgACAAIAAgAGMAdgAyAC4AQQBEAEEAUABUAEkAVgBFAF8AVABIAFIARQBTAEgAXwBHAEEAVQBTAFMASQBBAE4AXwBDACwACgAgACAAIAAgACAAIAAgACAAIAAgACAAYwB2ADIALgBUAEgAUgBFAFMASABfAEIASQBOAEEAUgBZACwAIAAxADEALAAgADIAKQAKAAoARQBkAGcAZQAgAEQAZQB0AGUAYwB0AGkAbwBuACAgFAAgAEMAYQBuAG4AeQAKAEQAZQB0AGUAYwB0AHMAIABiAG8AdQBuAGQAYQByAGkAZQBzACAAaQBuACAAYQBuACAAaQBtAGEAZwBlACAAYgB5ACAAZgBpAG4AZABpAG4AZwAgAGEAcgBlAGEAcwAgAG8AZgAgAHIAYQBwAGkAZAAgAGkAbgB0AGUAbgBzAGkAdAB5ACAAYwBoAGEAbgBnAGUALgAgAEMAYQBuAG4AeQAgAGkAcwAgAHQAaABlACAAbQBvAHMAdAAgAGMAbwBtAG0AbwBuAGwAeQAgAHUAcwBlAGQAIABlAGQAZwBlACAAZABlAHQAZQBjAHQAbwByAC4ACgBwAHkAdABoAG8AbgBlAGQAZwBlAHMAIAA9ACAAYwB2ADIALgBDAGEAbgBuAHkAKABnAHIAYQB5ACwAIAB0AGgAcgBlAHMAaABvAGwAZAAxAD0AMQAwADAALAAKACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgAHQAaAByAGUAcwBoAG8AbABkADIAPQAyADAAMAApAAoAYwB2ADIALgBpAG0AcwBoAG8AdwAoACIARQBkAGcAZQBzACIALAAgAGUAZABnAGUAcwApAAoAYwB2ADIALgB3AGEAaQB0AEsAZQB5ACgAMAApAAoACgBDAG8AbgB0AG8AdQByAHMAICAUACAAcwBoAGEAcABlACAAZABlAHQAZQBjAHQAaQBvAG4ACgBDAG8AbgB0AG8AdQByAHMAIABhAHIAZQAgAGMAdQByAHYAZQBzACAAdABoAGEAdAAgAGoAbwBpAG4AIABjAG8AbgB0AGkAbgB1AG8AdQBzACAAcABvAGkAbgB0AHMAIABvAGYAIAB0AGgAZQAgAHMAYQBtAGUAIABjAG8AbABvAHIAIABvAHIAIABpAG4AdABlAG4AcwBpAHQAeQAuACAAVQBzAGUAZAAgAHQAbwAgAGQAZQB0AGUAYwB0ACAAYQBuAGQAIABhAG4AYQBsAHkAegBlACAAcwBoAGEAcABlAHMALAAgAGMAbwB1AG4AdAAgAG8AYgBqAGUAYwB0AHMALAAgAGEAbgBkACAAbQBlAGEAcwB1AHIAZQAgAGEAcgBlAGEAcwAuAAoAcAB5AHQAaABvAG4AYwBvAG4AdABvAHUAcgBzACwAIABfACAAPQAgAGMAdgAyAC4AZgBpAG4AZABDAG8AbgB0AG8AdQByAHMAKAB0AGgAcgBlAHMAaAAsAAoAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAYwB2ADIALgBSAEUAVABSAF8ARQBYAFQARQBSAE4AQQBMACwACgAgACAAIAAgACAAIAAgACAAIAAgACAAIAAgACAAIABjAHYAMgAuAEMASABBAEkATgBfAEEAUABQAFIATwBYAF8AUwBJAE0AUABMAEUAKQAKAAoAZgBvAHIAIABjACAAaQBuACAAYwBvAG4AdABvAHUAcgBzADoACgAgACAAIAAgAGEAcgBlAGEAIAA9ACAAYwB2ADIALgBjAG8AbgB0AG8AdQByAEEAcgBlAGEAKABjACkACgAgACAAIAAgAGMAdgAyAC4AZAByAGEAdwBDAG8AbgB0AG8AdQByAHMAKABpAG0AZwAsACAAWwBjAF0ALAAgAC0AMQAsACAAKAAwACwAMgA1ADUALAAwACkALAAgADIAKQAKAAoAQgBsAHUAcgByAGkAbgBnACAAJgAgAFMAbQBvAG8AdABoAGkAbgBnACAgFAAgAG4AbwBpAHMAZQAgAHIAZQBkAHUAYwB0AGkAbwBuAAoAUgBlAGQAdQBjAGUAcwAgAG4AbwBpAHMAZQAgAGEAbgBkACAAZABlAHQAYQBpAGwAIABiAGUAZgBvAHIAZQAgAHAAcgBvAGMAZQBzAHMAaQBuAGcALgAgAEcAYQB1AHMAcwBpAGEAbgAgAGIAbAB1AHIAIABpAHMAIABtAG8AcwB0ACAAYwBvAG0AbQBvAG4AOwAgAGIAaQBsAGEAdABlAHIAYQBsACAAYgBsAHUAcgAgAHAAcgBlAHMAZQByAHYAZQBzACAAZQBkAGcAZQBzACAAdwBoAGkAbABlACAAcwBtAG8AbwB0AGgAaQBuAGcALgAKAHAAeQB0AGgAbwBuAGIAbAB1AHIAIAAgACAAIAAgAD0AIABjAHYAMgAuAEcAYQB1AHMAcwBpAGEAbgBCAGwAdQByACgAaQBtAGcALAAgACgANQAsACAANQApACwAIAAwACkACgBiAGkAbABhAHQAZQByAGEAbAAgAD0AIABjAHYAMgAuAGIAaQBsAGEAdABlAHIAYQBsAEYAaQBsAHQAZQByACgAaQBtAGcALAAgADkALAAgADcANQAsACAANwA1ACkACgBtAGUAZABpAGEAbgAgACAAIAA9ACAAYwB2ADIALgBtAGUAZABpAGEAbgBCAGwAdQByACgAaQBtAGcALAAgADUAKQAKAAoARgBlAGEAdAB1AHIAZQAgAEQAZQB0AGUAYwB0AGkAbwBuACAgFAAgAGsAZQB5AHAAbwBpAG4AdABzAAoASQBkAGUAbgB0AGkAZgBpAGUAcwAgAGkAbgB0AGUAcgBlAHMAdABpAG4AZwAgAHAAbwBpAG4AdABzACAAaQBuACAAYQBuACAAaQBtAGEAZwBlACAAdABoAGEAdAAgAGEAcgBlACAAcwB0AGEAYgBsAGUAIABhAGMAcgBvAHMAcwAgAHMAYwBhAGwAZQAsACAAcgBvAHQAYQB0AGkAbwBuACwAIABhAG4AZAAgAGwAaQBnAGgAdABpAG4AZwAgAGMAaABhAG4AZwBlAHMALgAgAFUAcwBlAGQAIABpAG4AIABvAGIAagBlAGMAdAAgAG0AYQB0AGMAaABpAG4AZwAgAGEAbgBkACAAcABhAG4AbwByAGEAbQBhACAAcwB0AGkAdABjAGgAaQBuAGcALgAKAHAAeQB0AGgAbwBuAG8AcgBiACAAPQAgAGMAdgAyAC4ATwBSAEIAXwBjAHIAZQBhAHQAZQAoACkACgBrAGUAeQBwAG8AaQBuAHQAcwAsACAAZABlAHMAYwByAGkAcAB0AG8AcgBzACAAPQAgAG8AcgBiAC4AZABlAHQAZQBjAHQAQQBuAGQAQwBvAG0AcAB1AHQAZQAoAGcAcgBhAHkALAAgAE4AbwBuAGUAKQAKAAoAaQBtAGcAXwBrAHAAIAA9ACAAYwB2ADIALgBkAHIAYQB3AEsAZQB5AHAAbwBpAG4AdABzACgAaQBtAGcALAAgAGsAZQB5AHAAbwBpAG4AdABzACwAIABOAG8AbgBlACkACgAKAE8AYgBqAGUAYwB0ACAARABlAHQAZQBjAHQAaQBvAG4AIAB3AGkAdABoACAAWQBPAEwATwAgIBQAIABkAGUAZQBwACAAbABlAGEAcgBuAGkAbgBnAAoAWQBPAEwATwAgACgAWQBvAHUAIABPAG4AbAB5ACAATABvAG8AawAgAE8AbgBjAGUAKQAgAGkAcwAgAGEAIAByAGUAYQBsAC0AdABpAG0AZQAgAG8AYgBqAGUAYwB0ACAAZABlAHQAZQBjAHQAaQBvAG4AIABtAG8AZABlAGwAIAB0AGgAYQB0ACAAcAByAGUAZABpAGMAdABzACAAYgBvAHUAbgBkAGkAbgBnACAAYgBvAHgAZQBzACAAYQBuAGQAIABjAGwAYQBzAHMAIABsAGEAYgBlAGwAcwAgAGkAbgAgAGEAIABzAGkAbgBnAGwAZQAgAGYAbwByAHcAYQByAGQAIABwAGEAcwBzACAAdABoAHIAbwB1AGcAaAAgAGEAIABuAGUAdQByAGEAbAAgAG4AZQB0AHcAbwByAGsALgAKAHAAeQB0AGgAbwBuAGYAcgBvAG0AIAB1AGwAdAByAGEAbAB5AHQAaQBjAHMAIABpAG0AcABvAHIAdAAgAFkATwBMAE8ACgAKAG0AbwBkAGUAbAAgAD0AIABZAE8ATABPACgAIgB5AG8AbABvAHYAOABuAC4AcAB0ACIAKQAKAHIAZQBzAHUAbAB0AHMAIAA9ACAAbQBvAGQAZQBsACgAIgBwAGgAbwB0AG8ALgBqAHAAZwAiACkACgAKAGYAbwByACAAYgBvAHgAIABpAG4AIAByAGUAcwB1AGwAdABzAFsAMABdAC4AYgBvAHgAZQBzADoACgAgACAAIAAgAHAAcgBpAG4AdAAoAGIAbwB4AC4AYwBsAHMALAAgAGIAbwB4AC4AYwBvAG4AZgAsACAAYgBvAHgALgB4AHkAeAB5ACkACgAKAEYAYQBjAGUAIABEAGUAdABlAGMAdABpAG8AbgAgIBQAIABIAGEAYQByACAAYwBhAHMAYwBhAGQAZQAKAE8AcABlAG4AQwBWACAAaQBuAGMAbAB1AGQAZQBzACAAcAByAGUALQB0AHIAYQBpAG4AZQBkACAAYwBsAGEAcwBzAGkAZgBpAGUAcgBzACAAZgBvAHIAIABkAGUAdABlAGMAdABpAG4AZwAgAGYAYQBjAGUAcwAsACAAZQB5AGUAcwAsACAAYQBuAGQAIABvAHQAaABlAHIAIABmAGUAYQB0AHUAcgBlAHMAIAB1AHMAaQBuAGcAIABIAGEAYQByACAAYwBhAHMAYwBhAGQAZQBzACAgFAAgAGEAIABmAGEAcwB0ACwAIABjAGwAYQBzAHMAaQBjAGEAbAAgAGEAcABwAHIAbwBhAGMAaAAuAAoAcAB5AHQAaABvAG4AZgBhAGMAZQBfAGMAYQBzAGMAYQBkAGUAIAA9ACAAYwB2ADIALgBDAGEAcwBjAGEAZABlAEMAbABhAHMAcwBpAGYAaQBlAHIAKAAKACAAIABjAHYAMgAuAGQAYQB0AGEALgBoAGEAYQByAGMAYQBzAGMAYQBkAGUAcwAgACsACgAgACAAIgBoAGEAYQByAGMAYQBzAGMAYQBkAGUAXwBmAHIAbwBuAHQAYQBsAGYAYQBjAGUAXwBkAGUAZgBhAHUAbAB0AC4AeABtAGwAIgApAAoACgBmAGEAYwBlAHMAIAA9ACAAZgBhAGMAZQBfAGMAYQBzAGMAYQBkAGUALgBkAGUAdABlAGMAdABNAHUAbAB0AGkAUwBjAGEAbABlACgAZwByAGEAeQAsACAAMQAuADEALAAgADQAKQAKAGYAbwByACAAKAB4ACwAIAB5ACwAIAB3ACwAIABoACkAIABpAG4AIABmAGEAYwBlAHMAOgAKACAAIAAgACAAYwB2ADIALgByAGUAYwB0AGEAbgBnAGwAZQAoAGkAbQBnACwAIAAoAHgALAB5ACkALAAgACgAeAArAHcALAAgAHkAKwBoACkALAAgACgAMgA1ADUALAAwACwAMAApACwAIAAyACkACgAKAE8AcAB0AGkAYwBhAGwAIABGAGwAbwB3ACAgFAAgAG0AbwB0AGkAbwBuACAAdAByAGEAYwBrAGkAbgBnAAoAVAByAGEAYwBrAHMAIAB0AGgAZQAgAG0AbwB2AGUAbQBlAG4AdAAgAG8AZgAgAHAAaQB4AGUAbABzACAAbwByACAAZgBlAGEAdAB1AHIAZQBzACAAYgBlAHQAdwBlAGUAbgAgAGYAcgBhAG0AZQBzACAAaQBuACAAYQAgAHYAaQBkAGUAbwAuACAATAB1AGMAYQBzAC0ASwBhAG4AYQBkAGUAIABpAHMAIABhACAAYwBsAGEAcwBzAGkAYwAgAHMAcABhAHIAcwBlACAAbQBlAHQAaABvAGQAOwAgAHUAcwBlAGQAIABpAG4AIABhAGMAdABpAG8AbgAgAHIAZQBjAG8AZwBuAGkAdABpAG8AbgAgAGEAbgBkACAAbwBiAGoAZQBjAHQAIAB0AHIAYQBjAGsAaQBuAGcALgAKAHAAeQB0AGgAbwBuAHAAcgBlAHYAXwBnAHIAYQB5ACAAPQAgAGMAdgAyAC4AYwB2AHQAQwBvAGwAbwByACgAcAByAGUAdgBfAGYAcgBhAG0AZQAsACAAYwB2ADIALgBDAE8ATABPAFIAXwBCAEcAUgAyAEcAUgBBAFkAKQAKAGMAdQByAHIAXwBnAHIAYQB5ACAAPQAgAGMAdgAyAC4AYwB2AHQAQwBvAGwAbwByACgAYwB1AHIAcgBfAGYAcgBhAG0AZQAsACAAYwB2ADIALgBDAE8ATABPAFIAXwBCAEcAUgAyAEcAUgBBAFkAKQAKAAoAZgBsAG8AdwAgAD0AIABjAHYAMgAuAGMAYQBsAGMATwBwAHQAaQBjAGEAbABGAGwAbwB3AEYAYQByAG4AZQBiAGEAYwBrACgACgAgACAAIAAgACAAIAAgACAAIABwAHIAZQB2AF8AZwByAGEAeQAsACAAYwB1AHIAcgBfAGcAcgBhAHkALAAgAE4AbwBuAGUALAAKACAAIAAgACAAIAAgACAAIAAgADAALgA1ACwAIAAzACwAIAAxADUALAAgADMALAAgADUALAAgADEALgAyACwAIAAwACnSGBkaG1okY2xhc3NuYW1lWCRjbGFzc2VzXxAPTlNNdXRhYmxlU3RyaW5noxwdHl8QD05TTXV0YWJsZVN0cmluZ1hOU1N0cmluZ1hOU09iamVjdNMgIQ4iJipXTlMua2V5c1pOUy5vYmplY3RzoyMkJYAFgAaAB6MnKCmACIAKgAyAFFdOU0NvbG9yXxAQTlNQYXJhZ3JhcGhTdHlsZVZOU0ZvbnTYLzAxMjMONDU2Nzg5Ojs8PV8QFVVJQ29sb3JDb21wb25lbnRDb3VudFdVSUdyZWVuVlVJQmx1ZVdVSUFscGhhVU5TUkdCVVVJUmVkXE5TQ29sb3JTcGFjZRAEIj9l5eYiP2Tk5SI/gAAATxARMC45MDYgMC44OTggMC44OTSACSI/Z+foEALTGBk/QEFCWyRjbGFzc2hpbnRzV1VJQ29sb3KiQB6hQ1dOU0NvbG9y00UORkdISVpOU1RhYlN0b3BzW05TQWxpZ25tZW50gACACxAE0hgZS0xfEBdOU011dGFibGVQYXJhZ3JhcGhTdHlsZaNNTh5fEBdOU011dGFibGVQYXJhZ3JhcGhTdHlsZV8QEE5TUGFyYWdyYXBoU3R5bGXbUFFSU1QOVVZXWFlaWltcXV5fXUdcYl8QIlVJRm9udE1heGltdW1Qb2ludFNpemVBZnRlclNjYWxpbmdfEBlVSUZvbnRQb2ludFNpemVGb3JTY2FsaW5nXxAQVUlGb250RGVzY3JpcHRvclZOU05hbWVWTlNTaXplXFVJRm9udFRyYWl0c18QD1VJRm9udFBvaW50U2l6ZV8QGVVJRm9udFRleHRTdHlsZUZvclNjYWxpbmdaVUlGb250TmFtZVxVSVN5c3RlbUZvbnQjAAAAAAAAAACADoANI0AwAAAAAAAAgBYQAIAAgA0JXS5TRlVJLVJlZ3VsYXLTZQ5mZ2hpXxAXVUlGb250RGVzY3JpcHRvck9wdGlvbnNfEBpVSUZvbnREZXNjcmlwdG9yQXR0cmlidXRlcxKAAIQEgBWAD9MgIQ5rbiqibG2AEIARom9wgBKAE4AUXxATTlNGb250U2l6ZUF0dHJpYnV0ZV8QGE5TQ1RGb250VUlVc2FnZUF0dHJpYnV0ZV8QEkNURm9udFJlZ3VsYXJVc2FnZdIYGXZ3XE5TRGljdGlvbmFyeaJ2HtIYGXl6XxAQVUlGb250RGVzY3JpcHRvcqJ7Hl8QEFVJRm9udERlc2NyaXB0b3LTGBk/fX5/VlVJRm9udKJ9HqEt0hgZgYJfEBJOU0F0dHJpYnV0ZWRTdHJpbmeigR4ACAARABoAJAApADIANwBJAEwAUQBTAG4AdAB7AIQAiwCYAJoAnACeAKMArQCvHdUd2h3lHe4eAB4EHhYeHx4oHi8eNx5CHkYeSB5KHkweUB5SHlQeVh5YHmAecx56Hoseox6rHrIeuh7AHsYe0x7VHtoe3x7kHvge+h7/HwEfCB8UHxwfHx8hHykfMB87H0cfSR9LH00fUh9sH3Afih+dH7Qf2R/1IAggDyAWICMgNSBRIFwgaSByIHQgdiB/IIEggyCFIIcgiCCWIJ0gtyDUINkg2yDdIOQg5yDpIOsg7iDwIPIg9CEKISUhOiE/IUwhTyFUIWchaiF9IYQhiyGOIZAhlSGqAAAAAAAAAgEAAAAAAAAAgwAAAAAAAAAAAAAAAAAAIa0=',
            localFilePath: null,
            remoteURL:     null,
            mimeType:      null,
        },
        {
            name:         'Types of Neural Networks',
            resourceType: 'PDF',
            size:         '0.1 MB',
            content:      null,
            localFilePath: 'F8A8256D-4D72-4D75-8047-6F64800E48B4_Types of Neural Networks.pdf',
            remoteURL:     null,
            mimeType:      'application/pdf',
        },
    ]

    const newCvResourceIds = []

    for (const def of cvResourceDefs) {
        const existing = await db.collection('resources')
            .where('subjectId', '==', cvId)
            .where('name',      '==', def.name)
            .limit(1)
            .get()

        if (!existing.empty) {
            console.log(`Resource "${def.name}" already exists — skipping`)
            continue
        }

        const resourceId = db.collection('resources').doc().id
        const doc = {
            id:           resourceId,
            userId:       uid,
            subjectId:    cvId,
            name:         def.name,
            resourceType: def.resourceType,
            size:         def.size,
            tags:         [],
            isFavorite:   false,
            syncStatus:   'synced',
            createdAt:    ts(new Date('2026-05-01T00:00:00Z')),
            updatedAt:    ts(new Date('2026-05-01T00:00:00Z')),
        }
        if (def.content       !== null) doc.content       = def.content
        if (def.localFilePath !== null) doc.localFilePath = def.localFilePath
        if (def.remoteURL     !== null) doc.remoteURL     = def.remoteURL
        if (def.mimeType      !== null) doc.mimeType      = def.mimeType

        await db.collection('resources').doc(resourceId).set(doc)
        newCvResourceIds.push(resourceId)
        console.log(`Resource "${def.name}" created ✅`)
    }

    if (newCvResourceIds.length > 0) {
        const currentCv = await db.collection('subjects').doc(cvId).get()
        const existingCvResourceIds = currentCv.data().resourceIds || []
        const allCvResourceIds = [...new Set([...existingCvResourceIds, ...newCvResourceIds])]
        await db.collection('subjects').doc(cvId).update({
            resourceIds:   allCvResourceIds,
            resourceCount: allCvResourceIds.length,
            updatedAt:     ts(new Date()),
        })
        console.log(`Computer Vision subject resourceIds updated (${allCvResourceIds.length} total) ✅`)
    }

    // ── Study Paths (all three subjects, 5 topics each) ────────────────────────
    const studyPaths = [
        {
            subjectId: iosId, label: 'iOS',
            topics: [
                { id: 'IOS-T1', order: 1, title: 'Variables & Constants',
                  description: 'Understand mutable vs immutable values with var and let, and how Swift infers types automatically.',
                  subtopics: ['var vs let', 'Type Inference', 'Type Annotations', 'Constants Best Practice'],
                  weightPercent: 15, estimatedMinutes: 30, difficultyLevel: 2, completionPercent: 100.0, isCompleted: true },
                { id: 'IOS-T2', order: 2, title: 'Control Flow',
                  description: 'Direct program execution using for-in loops, while loops, if-else, and switch with pattern matching.',
                  subtopics: ['for-in Loop', 'while Loop', 'if-else', 'switch & Pattern Matching'],
                  weightPercent: 20, estimatedMinutes: 35, difficultyLevel: 2, completionPercent: 100.0, isCompleted: true },
                { id: 'IOS-T3', order: 3, title: 'Functions & Closures',
                  description: 'Define reusable functions with labelled parameters and return types, and use closures for callbacks and sorting.',
                  subtopics: ['Function Definition', 'Parameters & Return Types', 'Closures', 'Trailing Closure Syntax'],
                  weightPercent: 20, estimatedMinutes: 35, difficultyLevel: 3, completionPercent: 100.0, isCompleted: true },
                { id: 'IOS-T4', order: 4, title: 'Structs, Classes & Enums',
                  description: 'Learn value types vs reference types, when to prefer structs, and how Swift enums carry associated values.',
                  subtopics: ['Structs (Value Types)', 'Classes (Reference Types)', 'Optionals', 'Enums with Associated Values'],
                  weightPercent: 25, estimatedMinutes: 40, difficultyLevel: 4, completionPercent: 100.0, isCompleted: true },
                { id: 'IOS-T5', order: 5, title: 'SwiftUI Layouts',
                  description: 'Build responsive interfaces using SwiftUI stacks, spacing, scrollable content, lists, and grid layouts.',
                  subtopics: ['VStack / HStack / ZStack', 'Spacer & Padding', 'ScrollView', 'List', 'LazyVGrid'],
                  weightPercent: 20, estimatedMinutes: 40, difficultyLevel: 4 },
            ],
        },
        {
            subjectId: webId, label: 'Web Application',
            topics: [
                { id: 'WEB-T1', order: 1, title: 'What is an API',
                  description: 'Understand what an API is, how it defines a contract between systems, and its role in modern web applications.',
                  subtopics: ['API Definition', 'Request & Response', 'Endpoints', 'Real-world Examples'],
                  weightPercent: 15, estimatedMinutes: 30, difficultyLevel: 2, completionPercent: 100.0, isCompleted: true },
                { id: 'WEB-T2', order: 2, title: 'REST Principles',
                  description: 'Learn the six constraints of REST architecture and how they guide the design of scalable, stateless web services.',
                  subtopics: ['Statelessness', 'Client-Server', 'Uniform Interface', 'Layered System'],
                  weightPercent: 20, estimatedMinutes: 35, difficultyLevel: 3 },
                { id: 'WEB-T3', order: 3, title: 'HTTP Methods & Status Codes',
                  description: 'Master GET, POST, PUT, PATCH, DELETE and interpret the most common HTTP status codes in API responses.',
                  subtopics: ['GET / POST / PUT / DELETE', '2xx Success', '4xx Client Errors', '5xx Server Errors'],
                  weightPercent: 20, estimatedMinutes: 35, difficultyLevel: 3 },
                { id: 'WEB-T4', order: 4, title: 'JSON & Data Formats',
                  description: 'Parse and construct JSON payloads, handle nested objects and arrays, and compare JSON with XML.',
                  subtopics: ['JSON Structure', 'Parsing JSON', 'Nested Objects & Arrays', 'JSON vs XML'],
                  weightPercent: 20, estimatedMinutes: 35, difficultyLevel: 3 },
                { id: 'WEB-T5', order: 5, title: 'Authentication & Security',
                  description: 'Protect API endpoints using API keys, JWT tokens, and OAuth 2.0, and understand HTTPS and CORS.',
                  subtopics: ['API Keys', 'JWT Tokens', 'OAuth 2.0', 'HTTPS & CORS'],
                  weightPercent: 25, estimatedMinutes: 45, difficultyLevel: 5 },
            ],
        },
        {
            subjectId: cvId, label: 'Computer Vision',
            topics: [
                { id: 'CV-T1', order: 1, title: 'Image Fundamentals',
                  description: 'Understand how images are represented as arrays of numbers, including grayscale 2D arrays and colour 3D arrays.',
                  subtopics: ['Images as Arrays', 'Pixel Values', 'Grayscale vs Colour', 'Channel Order (BGR vs RGB)'],
                  weightPercent: 15, estimatedMinutes: 30, difficultyLevel: 2, completionPercent: 100.0, isCompleted: true },
                { id: 'CV-T2', order: 2, title: 'Colour Spaces & Thresholding',
                  description: 'Convert between BGR, HSV, and Grayscale colour spaces and apply thresholding to isolate objects from backgrounds.',
                  subtopics: ['cvtColor', 'HSV Colour Space', 'Binary Thresholding', 'Adaptive & Otsu Thresholding'],
                  weightPercent: 20, estimatedMinutes: 40, difficultyLevel: 3, completionPercent: 100.0, isCompleted: true },
                { id: 'CV-T3', order: 3, title: 'Edge & Contour Detection',
                  description: 'Detect boundaries and shapes using Canny edge detection and contour analysis to count and measure objects.',
                  subtopics: ['Canny Edge Detection', 'findContours', 'contourArea', 'drawContours'],
                  weightPercent: 20, estimatedMinutes: 45, difficultyLevel: 4 },
                { id: 'CV-T4', order: 4, title: 'Blurring & Feature Detection',
                  description: 'Reduce noise with blur filters then identify stable keypoints using ORB for object matching across images.',
                  subtopics: ['Gaussian Blur', 'Bilateral Filter', 'ORB Keypoints', 'detectAndCompute'],
                  weightPercent: 20, estimatedMinutes: 40, difficultyLevel: 4 },
                { id: 'CV-T5', order: 5, title: 'Object Detection with YOLO',
                  description: 'Apply the YOLO model to predict bounding boxes and class labels in a single forward pass through a neural network.',
                  subtopics: ['YOLO Architecture', 'Bounding Boxes', 'Confidence Scores', 'Non-Max Suppression'],
                  weightPercent: 25, estimatedMinutes: 60, difficultyLevel: 7 },
            ],
        },
    ]

    for (const path of studyPaths) {
        const pathRef = db.collection('subjects').doc(path.subjectId).collection('studyPath')
        const existing = await pathRef.get()
        for (const doc of existing.docs) await doc.ref.delete()
        if (existing.size > 0) console.log(`Cleared ${existing.size} existing topic(s) for ${path.label}`)

        const batch = db.batch()
        for (const t of path.topics) {
            batch.set(pathRef.doc(t.id), {
                id: t.id, subjectId: path.subjectId, userId: uid,
                order: t.order, title: t.title, description: t.description,
                subtopics: t.subtopics, weightPercent: t.weightPercent,
                estimatedMinutes: t.estimatedMinutes, difficultyLevel: t.difficultyLevel,
                resourceIds: [], completionPercent: t.completionPercent ?? 0.0, isCompleted: t.isCompleted ?? false,
                syncStatus: 'synced', generatedAt: ts(new Date('2026-05-01T00:00:00Z')),
            })
        }
        await batch.commit()
        await db.collection('subjects').doc(path.subjectId).update({
            topicCount: path.topics.length,
            updatedAt:  ts(new Date()),
        })
        console.log(`${path.label} study path: ${path.topics.length} topics ✅`)
    }

    // ── Quiz Attempts ──────────────────────────────────────────────────────────

    // Helper: build a selectedAnswers map, answering correctly for the given indices.
    function makeAnswers(questions, correctIndices) {
        const map = {}
        questions.forEach((q, i) => {
            map[q.id] = correctIndices.includes(i) ? q.correctOptionIndex : (q.correctOptionIndex === 0 ? 1 : 0)
        })
        return map
    }

    // ── Questions banks ──────────────────────────────────────────────────────

    const cvQ1 = [ // Image Fundamentals — 5 questions
        { id: 'CVQ1-Q1', number: 1, category: 'Image Fundamentals', questionText: 'What data type does OpenCV use to represent a grayscale image?', questionType: 'multipleChoice', options: ['2D NumPy array', '3D NumPy array', 'Python list', 'PIL Image'], correctOptionIndex: 0, expertTip: 'Grayscale images are 2D arrays of shape (height, width).', keyword: 'grayscale', points: 1 },
        { id: 'CVQ1-Q2', number: 2, category: 'Image Fundamentals', questionText: 'What is the shape of a colour image with height 480, width 640?', questionType: 'multipleChoice', options: ['(640, 480, 3)', '(480, 640, 3)', '(480, 640)', '(3, 480, 640)'], correctOptionIndex: 1, expertTip: 'OpenCV uses (height, width, channels) ordering.', keyword: 'shape', points: 1 },
        { id: 'CVQ1-Q3', number: 3, category: 'Image Fundamentals', questionText: 'What channel order does OpenCV use by default?', questionType: 'multipleChoice', options: ['RGB', 'BGR', 'HSV', 'RGBA'], correctOptionIndex: 1, expertTip: 'OpenCV loads images in BGR order, not RGB.', keyword: 'BGR', points: 1 },
        { id: 'CVQ1-Q4', number: 4, category: 'Image Fundamentals', questionText: 'What is the pixel value range for a standard 8-bit image?', questionType: 'multipleChoice', options: ['0 to 1', '0 to 255', '-128 to 127', '0 to 1024'], correctOptionIndex: 1, expertTip: '8-bit images store values from 0 (black) to 255 (white).', keyword: 'pixel value', points: 1 },
        { id: 'CVQ1-Q5', number: 5, category: 'Image Fundamentals', questionText: 'Which function reads an image file in OpenCV?', questionType: 'multipleChoice', options: ['cv2.open()', 'cv2.imread()', 'cv2.load()', 'cv2.read()'], correctOptionIndex: 1, expertTip: 'cv2.imread() returns the image as a NumPy array.', keyword: 'imread', points: 1 },
    ]

    const cvQ2 = [ // Colour Spaces & Thresholding — 6 questions
        { id: 'CVQ2-Q1', number: 1, category: 'Colour Spaces', questionText: 'Which function converts an image between colour spaces in OpenCV?', questionType: 'multipleChoice', options: ['cv2.changeColor()', 'cv2.cvtColor()', 'cv2.convert()', 'cv2.colorSpace()'], correctOptionIndex: 1, expertTip: 'cv2.cvtColor(img, code) handles all colour space conversions.', keyword: 'cvtColor', points: 1 },
        { id: 'CVQ2-Q2', number: 2, category: 'Colour Spaces', questionText: 'Why is HSV preferred over BGR for colour-based object detection?', questionType: 'multipleChoice', options: ['HSV is faster to compute', 'HSV separates hue from lighting', 'HSV uses less memory', 'HSV is more accurate'], correctOptionIndex: 1, expertTip: 'HSV isolates hue so lighting changes don\'t affect colour detection.', keyword: 'HSV', points: 1 },
        { id: 'CVQ2-Q3', number: 3, category: 'Thresholding', questionText: 'What does cv2.threshold() return?', questionType: 'multipleChoice', options: ['Just the threshold image', 'The threshold value and the image', 'Only the threshold value', 'A list of contours'], correctOptionIndex: 1, expertTip: 'cv2.threshold() returns a tuple: (retval, thresholdedImage).', keyword: 'threshold', points: 1 },
        { id: 'CVQ2-Q4', number: 4, category: 'Thresholding', questionText: 'Which thresholding method works best under uneven lighting?', questionType: 'multipleChoice', options: ['Binary thresholding', 'Otsu\'s method', 'Adaptive thresholding', 'Inverse thresholding'], correctOptionIndex: 2, expertTip: 'Adaptive thresholding calculates different thresholds for regions of the image.', keyword: 'adaptive', points: 1 },
        { id: 'CVQ2-Q5', number: 5, category: 'Thresholding', questionText: 'What does Otsu\'s thresholding automatically determine?', questionType: 'multipleChoice', options: ['Image brightness', 'Optimal threshold value', 'Contour count', 'Colour space'], correctOptionIndex: 1, expertTip: 'Otsu\'s method finds the threshold that minimises intra-class variance.', keyword: 'Otsu', points: 1 },
        { id: 'CVQ2-Q6', number: 6, category: 'Colour Spaces', questionText: 'What code converts BGR to Grayscale in OpenCV?', questionType: 'multipleChoice', options: ['cv2.COLOR_BGR2GRAY', 'cv2.COLOR_RGB2GRAY', 'cv2.GRAY', 'cv2.BGR_GRAY'], correctOptionIndex: 0, expertTip: 'cv2.COLOR_BGR2GRAY is the correct conversion code.', keyword: 'grayscale', points: 1 },
    ]

    const iosQ1 = [ // Variables & Constants — 5 questions
        { id: 'IOSQ1-Q1', number: 1, category: 'Variables & Constants', questionText: 'Which keyword declares a constant in Swift?', questionType: 'multipleChoice', options: ['var', 'let', 'const', 'val'], correctOptionIndex: 1, expertTip: 'let declares constants that cannot be changed after assignment.', keyword: 'let', points: 1 },
        { id: 'IOSQ1-Q2', number: 2, category: 'Variables & Constants', questionText: 'What does Swift type inference do?', questionType: 'multipleChoice', options: ['Forces you to declare all types', 'Automatically determines a variable\'s type from its value', 'Converts types at runtime', 'Requires explicit type annotations'], correctOptionIndex: 1, expertTip: 'Swift infers the type from the assigned value so you don\'t always need to write it.', keyword: 'type inference', points: 1 },
        { id: 'IOSQ1-Q3', number: 3, category: 'Variables & Constants', questionText: 'What is the correct type annotation syntax for a Double?', questionType: 'multipleChoice', options: ['var x = Double', 'var x: Double = 0.0', 'var x as Double', 'Double var x'], correctOptionIndex: 1, expertTip: 'Type annotations use a colon: var name: Type = value.', keyword: 'annotation', points: 1 },
        { id: 'IOSQ1-Q4', number: 4, category: 'Variables & Constants', questionText: 'Which of these causes a compile error in Swift?', questionType: 'multipleChoice', options: ['var x = 5; x = 10', 'let y = 5', 'var z: String = "hello"', 'let n = 1; n = 2'], correctOptionIndex: 3, expertTip: 'You cannot reassign a let constant after its initial value is set.', keyword: 'constant', points: 1 },
        { id: 'IOSQ1-Q5', number: 5, category: 'Variables & Constants', questionText: 'What type does Swift infer for: var score = 100?', questionType: 'multipleChoice', options: ['Double', 'Float', 'Int', 'Number'], correctOptionIndex: 2, expertTip: 'Integer literals without a decimal point are inferred as Int.', keyword: 'Int', points: 1 },
    ]

    const iosQ2 = [ // Control Flow — 5 questions
        { id: 'IOSQ2-Q1', number: 1, category: 'Control Flow', questionText: 'What does the for-in loop iterate over?', questionType: 'multipleChoice', options: ['Only arrays', 'Ranges and collections', 'Only dictionaries', 'Only integers'], correctOptionIndex: 1, expertTip: 'for-in works with any Sequence, including ranges, arrays, and strings.', keyword: 'for-in', points: 1 },
        { id: 'IOSQ2-Q2', number: 2, category: 'Control Flow', questionText: 'What range operator creates a range that EXCLUDES the upper bound?', questionType: 'multipleChoice', options: ['1...5', '1..<5', '1..5', '1->5'], correctOptionIndex: 1, expertTip: '1..<5 produces 1, 2, 3, 4. Use ... to include the upper bound.', keyword: 'range', points: 1 },
        { id: 'IOSQ2-Q3', number: 3, category: 'Control Flow', questionText: 'Does Swift\'s switch statement fall through by default?', questionType: 'multipleChoice', options: ['Yes, like C', 'No, each case breaks automatically', 'Only for integer cases', 'Only with the fallthrough keyword'], correctOptionIndex: 1, expertTip: 'Swift switch cases break automatically. Use fallthrough explicitly if needed.', keyword: 'switch', points: 1 },
        { id: 'IOSQ2-Q4', number: 4, category: 'Control Flow', questionText: 'Which loop is guaranteed to run its body at least once?', questionType: 'multipleChoice', options: ['for-in', 'while', 'repeat-while', 'guard'], correctOptionIndex: 2, expertTip: 'repeat-while checks its condition after the body executes.', keyword: 'repeat-while', points: 1 },
        { id: 'IOSQ2-Q5', number: 5, category: 'Control Flow', questionText: 'Can a Swift switch case match a range?', questionType: 'multipleChoice', options: ['No', 'Yes, using range patterns', 'Only with if-let', 'Only for strings'], correctOptionIndex: 1, expertTip: 'Swift switch supports range patterns: case 1...10: print("low").', keyword: 'pattern matching', points: 1 },
    ]

    const iosQ3 = [ // Functions & Closures — 6 questions
        { id: 'IOSQ3-Q1', number: 1, category: 'Functions', questionText: 'What symbol specifies a function\'s return type in Swift?', questionType: 'multipleChoice', options: [':', '=>', '->', '::'], correctOptionIndex: 2, expertTip: 'func greet() -> String specifies that the function returns a String.', keyword: 'return type', points: 1 },
        { id: 'IOSQ3-Q2', number: 2, category: 'Functions', questionText: 'In Swift, what is the external parameter label used for?', questionType: 'multipleChoice', options: ['Naming the return value', 'Labelling arguments at the call site', 'Declaring optional parameters', 'Setting default values'], correctOptionIndex: 1, expertTip: 'External labels make call sites readable: greet(name: "Ana").', keyword: 'parameter label', points: 1 },
        { id: 'IOSQ3-Q3', number: 3, category: 'Closures', questionText: 'What is a closure in Swift?', questionType: 'multipleChoice', options: ['A type of class', 'A self-contained block of functionality', 'A protocol', 'A property wrapper'], correctOptionIndex: 1, expertTip: 'Closures are anonymous functions that can capture values from their surrounding scope.', keyword: 'closure', points: 1 },
        { id: 'IOSQ3-Q4', number: 4, category: 'Closures', questionText: 'What does $0 refer to inside a closure?', questionType: 'multipleChoice', options: ['The closure\'s return value', 'The first argument', 'The closure itself', 'The captured variable'], correctOptionIndex: 1, expertTip: '$0, $1 etc. are shorthand argument names for closure parameters.', keyword: 'shorthand arguments', points: 1 },
        { id: 'IOSQ3-Q5', number: 5, category: 'Functions', questionText: 'How do you use _ to suppress an external parameter label?', questionType: 'multipleChoice', options: ['func f(x _: Int)', 'func f(_ x: Int)', 'func f(x: _ Int)', 'func f(-x: Int)'], correctOptionIndex: 1, expertTip: 'func greet(_ name: String) allows calling greet("Ana") without a label.', keyword: 'underscore', points: 1 },
        { id: 'IOSQ3-Q6', number: 6, category: 'Closures', questionText: 'When a closure is the last argument, it can be written as a...?', questionType: 'multipleChoice', options: ['Inline closure', 'Trailing closure', 'Escaping closure', 'Capture closure'], correctOptionIndex: 1, expertTip: 'Trailing closure syntax moves the closure outside the parentheses for readability.', keyword: 'trailing closure', points: 1 },
    ]

    const iosQ4 = [ // Structs, Classes & Enums — 6 questions
        { id: 'IOSQ4-Q1', number: 1, category: 'Structs & Classes', questionText: 'What is the key difference between a struct and a class in Swift?', questionType: 'multipleChoice', options: ['Structs can\'t have methods', 'Structs are value types, classes are reference types', 'Classes can\'t conform to protocols', 'Structs are slower'], correctOptionIndex: 1, expertTip: 'Structs are copied on assignment; classes share a reference.', keyword: 'value vs reference', points: 1 },
        { id: 'IOSQ4-Q2', number: 2, category: 'Structs & Classes', questionText: 'Which is generally preferred in Swift for simple data models?', questionType: 'multipleChoice', options: ['Classes', 'Structs', 'Enums', 'Protocols'], correctOptionIndex: 1, expertTip: 'Apple recommends structs for most data models because they\'re safer with value semantics.', keyword: 'struct preference', points: 1 },
        { id: 'IOSQ4-Q3', number: 3, category: 'Optionals', questionText: 'What does var age: Int? mean in Swift?', questionType: 'multipleChoice', options: ['age must always have a value', 'age can be nil', 'age is a Double', 'age is optional only in classes'], correctOptionIndex: 1, expertTip: 'The ? marks a type as Optional, meaning it can hold a value or nil.', keyword: 'optional', points: 1 },
        { id: 'IOSQ4-Q4', number: 4, category: 'Optionals', questionText: 'Which is the safest way to unwrap an optional?', questionType: 'multipleChoice', options: ['Force unwrap with !', 'if let binding', 'Ignoring the optional', 'Using as! cast'], correctOptionIndex: 1, expertTip: 'if let safely unwraps only when the value is non-nil.', keyword: 'if let', points: 1 },
        { id: 'IOSQ4-Q5', number: 5, category: 'Enums', questionText: 'Can Swift enums have associated values?', questionType: 'multipleChoice', options: ['No', 'Yes', 'Only string values', 'Only in classes'], correctOptionIndex: 1, expertTip: 'Swift enums can carry associated values: case success(String), case failure(Error).', keyword: 'associated values', points: 1 },
        { id: 'IOSQ4-Q6', number: 6, category: 'Enums', questionText: 'What is a raw value enum?', questionType: 'multipleChoice', options: ['An enum with no cases', 'An enum where each case maps to a fixed underlying value', 'An enum without methods', 'An enum that conforms to Codable only'], correctOptionIndex: 1, expertTip: 'enum Direction: String gives each case a String raw value.', keyword: 'raw value', points: 1 },
    ]

    const webQ1 = [ // What is an API — 5 questions
        { id: 'WEBQ1-Q1', number: 1, category: 'API Basics', questionText: 'What does API stand for?', questionType: 'multipleChoice', options: ['Application Performance Interface', 'Application Programming Interface', 'Automated Processing Interface', 'Application Protocol Integration'], correctOptionIndex: 1, expertTip: 'API = Application Programming Interface — a contract for how software components interact.', keyword: 'API definition', points: 1 },
        { id: 'WEBQ1-Q2', number: 2, category: 'API Basics', questionText: 'What is an API endpoint?', questionType: 'multipleChoice', options: ['A database table', 'A specific URL where an API can be accessed', 'A programming language', 'A server hardware component'], correctOptionIndex: 1, expertTip: 'An endpoint is the URL path where a specific API operation is available.', keyword: 'endpoint', points: 1 },
        { id: 'WEBQ1-Q3', number: 3, category: 'API Basics', questionText: 'In an API request-response cycle, who initiates the request?', questionType: 'multipleChoice', options: ['The server', 'The database', 'The client', 'The API gateway'], correctOptionIndex: 2, expertTip: 'The client (app/browser) sends requests; the server processes and responds.', keyword: 'client-server', points: 1 },
        { id: 'WEBQ1-Q4', number: 4, category: 'API Basics', questionText: 'Which real-world analogy best describes an API?', questionType: 'multipleChoice', options: ['A filing cabinet', 'A waiter taking orders between customer and kitchen', 'A telephone line', 'A database index'], correctOptionIndex: 1, expertTip: 'Like a waiter, the API carries requests to the backend and brings results back.', keyword: 'analogy', points: 1 },
        { id: 'WEBQ1-Q5', number: 5, category: 'API Basics', questionText: 'What does an API response typically contain?', questionType: 'multipleChoice', options: ['Only error codes', 'Data and a status code', 'Only the requested HTML page', 'The server\'s IP address'], correctOptionIndex: 1, expertTip: 'API responses include a status code and a body (usually JSON data).', keyword: 'response', points: 1 },
    ]

    // ── Build attempt documents ──────────────────────────────────────────────

    const quizAttempts = [
        // CV Topic 1 — 2 attempts
        {
            id: 'QA-CV1-A1', quizName: 'Image Fundamentals Quiz', topicName: 'Image Fundamentals',
            subjectId: cvId, questions: cvQ1, correctIndices: [0, 2, 3],          // 3/5 = 60%
            timeSpentSeconds: 312, completedAt: new Date('2026-05-05T08:00:00Z'),
        },
        {
            id: 'QA-CV1-A2', quizName: 'Image Fundamentals Quiz', topicName: 'Image Fundamentals',
            subjectId: cvId, questions: cvQ1, correctIndices: [0, 1, 2, 4],       // 4/5 = 80%
            timeSpentSeconds: 278, completedAt: new Date('2026-05-06T09:00:00Z'),
        },
        // CV Topic 2 — 3 attempts
        {
            id: 'QA-CV2-A1', quizName: 'Colour Spaces & Thresholding Quiz', topicName: 'Colour Spaces & Thresholding',
            subjectId: cvId, questions: cvQ2, correctIndices: [0, 1, 3],          // 3/6 = 50%
            timeSpentSeconds: 420, completedAt: new Date('2026-05-08T10:00:00Z'),
        },
        {
            id: 'QA-CV2-A2', quizName: 'Colour Spaces & Thresholding Quiz', topicName: 'Colour Spaces & Thresholding',
            subjectId: cvId, questions: cvQ2, correctIndices: [0, 1, 2, 4],       // 4/6 = 67%
            timeSpentSeconds: 385, completedAt: new Date('2026-05-09T11:00:00Z'),
        },
        {
            id: 'QA-CV2-A3', quizName: 'Colour Spaces & Thresholding Quiz', topicName: 'Colour Spaces & Thresholding',
            subjectId: cvId, questions: cvQ2, correctIndices: [0, 1, 2, 3, 5],    // 5/6 = 83%
            timeSpentSeconds: 340, completedAt: new Date('2026-05-10T12:00:00Z'),
        },
        // iOS — 4 quizzes, 1 attempt each
        {
            id: 'QA-IOS1-A1', quizName: 'Variables & Constants Quiz', topicName: 'Variables & Constants',
            subjectId: iosId, questions: iosQ1, correctIndices: [0, 1, 2, 4],     // 4/5 = 80%
            timeSpentSeconds: 290, completedAt: new Date('2026-05-03T08:00:00Z'),
        },
        {
            id: 'QA-IOS2-A1', quizName: 'Control Flow Quiz', topicName: 'Control Flow',
            subjectId: iosId, questions: iosQ2, correctIndices: [0, 1, 2, 3],     // 4/5 = 80%
            timeSpentSeconds: 310, completedAt: new Date('2026-05-05T09:00:00Z'),
        },
        {
            id: 'QA-IOS3-A1', quizName: 'Functions & Closures Quiz', topicName: 'Functions & Closures',
            subjectId: iosId, questions: iosQ3, correctIndices: [0, 1, 2, 3, 5],  // 5/6 = 83%
            timeSpentSeconds: 360, completedAt: new Date('2026-05-07T10:00:00Z'),
        },
        {
            id: 'QA-IOS4-A1', quizName: 'Structs, Classes & Enums Quiz', topicName: 'Structs, Classes & Enums',
            subjectId: iosId, questions: iosQ4, correctIndices: [0, 1, 3, 4],     // 4/6 = 67%
            timeSpentSeconds: 410, completedAt: new Date('2026-05-09T11:00:00Z'),
        },
        // Web — 1 quiz, 1 attempt
        {
            id: 'QA-WEB1-A1', quizName: 'What is an API Quiz', topicName: 'What is an API',
            subjectId: webId, questions: webQ1, correctIndices: [0, 1, 2, 4],     // 4/5 = 80%
            timeSpentSeconds: 265, completedAt: new Date('2026-05-04T08:00:00Z'),
        },
    ]

    for (const a of quizAttempts) {
        const existing = await db.collection('quizAttempts').doc(a.id).get()
        if (existing.exists) { console.log(`Quiz attempt "${a.quizName}" (${a.id}) already exists — skipping`); continue }

        const selectedAnswers = makeAnswers(a.questions, a.correctIndices)
        const scorePercent    = Math.round(a.correctIndices.length * 100 / a.questions.length)

        const questionsData = a.questions.map(q => ({
            id: q.id, number: q.number, category: q.category,
            questionText: q.questionText, questionType: q.questionType,
            options: q.options, correctOptionIndex: q.correctOptionIndex,
            expertTip: q.expertTip, keyword: q.keyword,
            hint: q.hint ?? null, points: q.points,
        }))

        await db.collection('quizAttempts').doc(a.id).set({
            id:               a.id,
            userId:           uid,
            quizId:           '',
            quizName:         a.quizName,
            topicName:        a.topicName,
            subjectId:        a.subjectId,
            questions:        questionsData,
            selectedAnswers,
            scorePercent,
            timeSpentSeconds: a.timeSpentSeconds,
            completedAt:      ts(a.completedAt),
            createdAt:        ts(a.completedAt),
            updatedAt:        ts(a.completedAt),
            syncStatus:       'synced',
        })
        console.log(`Quiz attempt "${a.quizName}" — ${scorePercent}% `)
    }

    // ── Availability Slots — delete only known seeded IDs, leave user slots untouched ──
    const seededSlotIds = Array.from({length: 15}, (_, i) => `AVAIL-SLOT-${String(i+1).padStart(2,'0')}`)
    for (const id of seededSlotIds) {
        await db.collection('availabilitySlots').doc(id).delete()
    }
    console.log('Cleared previous seeded availability slots')

    // Seed one specificDate slot per day (May 2–16) — same format the app produces via expandRangeSlot().
    const slotStart = new Date('2026-05-02T12:00:00Z') // 17:30 LK
    const slotEnd   = new Date('2026-05-02T16:00:00Z') // 21:30 LK

    for (let i = 0; i < 15; i++) {
        const slotId  = `AVAIL-SLOT-${String(i+1).padStart(2,'0')}`
        const slotDay = new Date('2026-05-02T00:00:00Z')
        slotDay.setUTCDate(slotDay.getUTCDate() + i)  // May 2, 3, 4 … 16

        await db.collection('availabilitySlots').doc(slotId).set({
            id:         slotId,
            userId:     uid,
            type:       'Date',          // specificDate — matches what the app writes
            startTime:  ts(slotStart),
            endTime:    ts(slotEnd),
            date:       ts(slotDay),    // required field for specificDate slots
            label:      'Evening Study Block',
            syncStatus: 'synced',
            createdAt:  ts(new Date('2026-05-01T00:00:00Z')),
            updatedAt:  ts(new Date('2026-05-01T00:00:00Z')),
        })
    }
    console.log('Availability slots created (May 2–16, one per day, 5:30–9:30 PM) ✅')

    // ── Study Sessions ─────────────────────────────────────────────────────────
    const sessionDefs = [
        // Before current week — not in streak window
        { id: 'SS-IOS-1', date: '2026-05-02', start: '2026-05-02T12:00:00Z', end: '2026-05-02T13:00:00Z',
          subjectId: iosId, subjectName: 'iOS', subjectColorHex: '#3B82F6',
          title: 'Variables & Constants', topic: 'Variables & Constants',
          topicIds: ['IOS-T1'], actualDurationMinutes: 60, sessionType: 'focused', rating: 4 },
        { id: 'SS-WEB-1', date: '2026-05-05', start: '2026-05-05T12:30:00Z', end: '2026-05-05T13:45:00Z',
          subjectId: webId, subjectName: 'Web Application', subjectColorHex: '#10B981',
          title: 'What is an API', topic: 'What is an API',
          topicIds: ['WEB-T1'], actualDurationMinutes: 75, sessionType: 'focused', rating: 4 },
        // Streak start: May 8–14 (7 consecutive days)
        { id: 'SS-CV-1', date: '2026-05-08', start: '2026-05-08T12:00:00Z', end: '2026-05-08T13:15:00Z',
          subjectId: cvId, subjectName: 'Computer Vision', subjectColorHex: '#EC4899',
          title: 'Image Fundamentals', topic: 'Image Fundamentals',
          topicIds: ['CV-T1'], actualDurationMinutes: 75, sessionType: 'focused', rating: 3 },
        { id: 'SS-IOS-2', date: '2026-05-09', start: '2026-05-09T12:30:00Z', end: '2026-05-09T14:00:00Z',
          subjectId: iosId, subjectName: 'iOS', subjectColorHex: '#3B82F6',
          title: 'Control Flow', topic: 'Control Flow',
          topicIds: ['IOS-T2'], actualDurationMinutes: 90, sessionType: 'focused', rating: 5 },
        { id: 'SS-CV-2', date: '2026-05-10', start: '2026-05-10T12:00:00Z', end: '2026-05-10T13:15:00Z',
          subjectId: cvId, subjectName: 'Computer Vision', subjectColorHex: '#EC4899',
          title: 'Colour Spaces & Thresholding', topic: 'Colour Spaces & Thresholding',
          topicIds: ['CV-T2'], actualDurationMinutes: 75, sessionType: 'focused', rating: 4 },
        // This week: May 11–14 (4 sessions > last week's 3 = IMPROVING)
        { id: 'SS-IOS-3', date: '2026-05-11', start: '2026-05-11T12:30:00Z', end: '2026-05-11T14:00:00Z',
          subjectId: iosId, subjectName: 'iOS', subjectColorHex: '#3B82F6',
          title: 'Functions & Closures', topic: 'Functions & Closures',
          topicIds: ['IOS-T3'], actualDurationMinutes: 90, sessionType: 'focused', rating: 4 },
        { id: 'SS-IOS-4', date: '2026-05-12', start: '2026-05-12T12:00:00Z', end: '2026-05-12T13:30:00Z',
          subjectId: iosId, subjectName: 'iOS', subjectColorHex: '#3B82F6',
          title: 'Structs, Classes & Enums', topic: 'Structs, Classes & Enums',
          topicIds: ['IOS-T4'], actualDurationMinutes: 90, sessionType: 'focused', rating: 3 },
        { id: 'SS-WEB-2', date: '2026-05-13', start: '2026-05-13T12:30:00Z', end: '2026-05-13T13:30:00Z',
          subjectId: webId, subjectName: 'Web Application', subjectColorHex: '#10B981',
          title: 'API Review', topic: 'What is an API',
          topicIds: ['WEB-T1'], actualDurationMinutes: 60, sessionType: 'review', rating: 4 },
        { id: 'SS-CV-3', date: '2026-05-14', start: '2026-05-14T12:00:00Z', end: '2026-05-14T12:45:00Z',
          subjectId: cvId, subjectName: 'Computer Vision', subjectColorHex: '#EC4899',
          title: 'CV Practice', topic: 'Colour Spaces & Thresholding',
          topicIds: ['CV-T2'], actualDurationMinutes: 45, sessionType: 'practice', rating: 5 },
    ]

    // Delete all existing sessions for this user before re-seeding
    const existingSessions = await db.collection('studySessions').where('userId', '==', uid).get()
    for (const doc of existingSessions.docs) {
        await db.collection('studySessions').doc(doc.id).delete()
    }
    console.log(`Deleted ${existingSessions.size} existing study session(s)`)

    for (const s of sessionDefs) {

        await db.collection('studySessions').doc(s.id).set({
            id:                    s.id,
            userId:                uid,
            subjectId:             s.subjectId,
            subjectName:           s.subjectName,
            subjectColorHex:       s.subjectColorHex,
            title:                 s.title,
            topic:                 s.topic,
            scheduledDate:         ts(new Date(s.date + 'T00:00:00Z')),
            startTime:             ts(new Date(s.start)),
            endTime:               ts(new Date(s.end)),
            actualDurationMinutes: s.actualDurationMinutes,
            status:                'completed',
            sessionType:           s.sessionType,
            topicIds:              s.topicIds,
            resourceIds:           [],
            hasReminder:           false,
            rating:                s.rating,
            syncStatus:            'synced',
            createdAt:             ts(new Date(s.start)),
            updatedAt:             ts(new Date(s.start)),
        })
        console.log(`Session "${s.title}" on ${s.date} (${s.actualDurationMinutes} min) ✅`)
    }

    // ── Update subjects with sessionIds and totalHoursStudied ──────────────────
    const subjectSessionMap = {
        [iosId]: {
            ids:   ['SS-IOS-1', 'SS-IOS-2', 'SS-IOS-3', 'SS-IOS-4'],
            hours: (60 + 90 + 90 + 90) / 60,  // 5.5h
        },
        [webId]: {
            ids:   ['SS-WEB-1', 'SS-WEB-2'],
            hours: (75 + 60) / 60,             // 2.25h
        },
        [cvId]: {
            ids:   ['SS-CV-1', 'SS-CV-2', 'SS-CV-3'],
            hours: (75 + 75 + 45) / 60,        // 3.25h
        },
    }

    for (const [subjectId, data] of Object.entries(subjectSessionMap)) {
        await db.collection('subjects').doc(subjectId).update({
            sessionIds:       admin.firestore.FieldValue.arrayUnion(...data.ids),
            totalHoursStudied: data.hours,
            updatedAt:         ts(new Date()),
        })
        console.log(`Subject ${subjectId} — sessionIds & totalHoursStudied updated ✅`)
    }

    console.log('\nDone')
    console.log(`  Email:    ${DEMO_EMAIL}`)
    console.log(`  Password: ${DEMO_PASSWORD}`)
    console.log(`  UID:      ${uid}`)
}

seed().catch(err => {
    console.error('Seed failed', err)
    process.exit(1)
})
