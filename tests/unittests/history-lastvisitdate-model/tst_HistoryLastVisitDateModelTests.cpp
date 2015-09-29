/*
 * Copyright 2015 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Qt
#include <QtTest/QSignalSpy>
#include <QtTest/QtTest>

// local
#include "bookmarks-model.h"
#include "history-lastvisitdate-model.h"
#include "history-model.h"
#include "history-timeframe-model.h"


class HistoryLastVisitDateModelTests : public QObject
{
    Q_OBJECT

private:
    HistoryModel* history;
    HistoryTimeframeModel* timeframe;
    HistoryLastVisitDateModel* model;

private Q_SLOTS:
    void init()
    {
        history = new HistoryModel;
        history->setDatabasePath(":memory:");
        timeframe = new HistoryTimeframeModel;
        timeframe->setSourceModel(history);
        model = new HistoryLastVisitDateModel;
        model->setSourceModel(QVariant::fromValue(timeframe));
    }

    void cleanup()
    {
        delete model;
        delete timeframe;
        delete history;
    }

    void shouldBeInitiallyEmpty()
    {
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldNotifyWhenChangingSourceModel()
    {
        QSignalSpy spy(model, SIGNAL(sourceModelChanged()));
        model->setSourceModel(QVariant::fromValue(timeframe));
        QVERIFY(spy.isEmpty());

        HistoryTimeframeModel* timeframe2 = new HistoryTimeframeModel(model);
        model->setSourceModel(QVariant::fromValue(timeframe2));
        QCOMPARE(spy.count(), 1);
        QCOMPARE(model->sourceModel(), QVariant::fromValue(timeframe2));

        model->setSourceModel(QVariant());
        QCOMPARE(spy.count(), 2);
        QVERIFY(!model->sourceModel().isValid());

        QTest::ignoreMessage(QtWarningMsg, "Only QAbstractItemModel-derived instances are allowed as source models");
        model->setSourceModel(QVariant::fromValue(QString("not a model")));
        QVERIFY(!model->sourceModel().isValid());
        QCOMPARE(model->rowCount(), 0);
        QCOMPARE(spy.count(), 2); // model is still invalid internally so no signal emitted

        QTest::ignoreMessage(QtWarningMsg, "No results will be returned because the sourceModel does not have a role named \"lastVisitDate\"");
        BookmarksModel bookmarks;
        bookmarks.setDatabasePath(":memory:");
        bookmarks.add(QUrl("http://example.org/"), "Example Domain", QUrl(), "");
        model->setSourceModel(QVariant::fromValue(&bookmarks));
        QCOMPARE(spy.count(), 3);
        // with no filter, all entries match even if the model doesn't have the lastVisitDate role
        QCOMPARE(model->rowCount(), 1);
        model->setLastVisitDate(QDate::currentDate());
        QCOMPARE(model->rowCount(), 0);

        delete timeframe2;
    }

    void shouldNotifyWhenChangingLastVisitDate()
    {
        QSignalSpy spy(model, SIGNAL(lastVisitDateChanged()));
        model->setLastVisitDate(QDate());
        QVERIFY(spy.isEmpty());
        model->setLastVisitDate(QDate::currentDate());
        QCOMPARE(spy.count(), 1);
    }

    void shouldMatchAllWhenNoLastVisitDateSet()
    {
        history->add(QUrl("http://example.org"), "Example Domain", QUrl());
        history->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(model->rowCount(), 2);
    }

    void shouldFilterOutNonMatchingLastVisitDate()
    {
        history->add(QUrl("http://example.org/"), "Example Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://example.com/"), "Example Domain", QUrl());
        model->setLastVisitDate(QDate::currentDate());
        QCOMPARE(model->rowCount(), 2);
        model->setLastVisitDate(QDate(1970, 1, 1));
        QCOMPARE(model->rowCount(), 0);
    }

    void shouldReturnDataByIndex()
    {
        history->add(QUrl("http://example.org"), "Example Domain", QUrl());
        QTest::qWait(1001);
        history->add(QUrl("http://example.com"), "Example Domain", QUrl());
        QCOMPARE(model->rowCount(), 2);
        QVariantMap entry = model->get(2);
        QVERIFY(entry.isEmpty());
        entry = model->get(1);
        QCOMPARE(entry.value("url").toUrl(), QUrl("http://example.org"));
    }
};

QTEST_MAIN(HistoryLastVisitDateModelTests)
#include "tst_HistoryLastVisitDateModelTests.moc"