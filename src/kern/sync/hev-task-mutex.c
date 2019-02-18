/*
 ============================================================================
 Name        : hev-task-mutex.c
 Author      : Heiher <r@hev.cc>
 Copyright   : Copyright (c) 2019 everyone.
 Description : Mutex
 ============================================================================
 */

#include <stddef.h>

#include "kern/task/hev-task.h"

#include "hev-task-mutex.h"

struct _HevTaskMutexNode
{
    HevTaskMutexNode *next;

    HevTask *task;
};

int
hev_task_mutex_init (HevTaskMutex *self)
{
    self->locker = 0;
    self->waiters = NULL;

    return 0;
}

int
hev_task_mutex_lock (HevTaskMutex *self)
{
    if (self->locker) {
        HevTaskMutexNode node;

        node.next = self->waiters;
        node.task = hev_task_self ();
        self->waiters = &node;

        do {
            hev_task_yield (HEV_TASK_WAITIO);
        } while (self->locker || self->waiters != &node);

        self->waiters = node.next;
    }

    self->locker = 1;

    return 0;
}

int
hev_task_mutex_trylock (HevTaskMutex *self)
{
    if (self->locker)
        return -1;

    self->locker = 1;

    return 0;
}

int
hev_task_mutex_unlock (HevTaskMutex *self)
{
    self->locker = 0;

    if (self->waiters)
        hev_task_wakeup (self->waiters->task);

    return 0;
}
