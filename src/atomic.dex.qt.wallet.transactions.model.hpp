#pragma once

#include <QAbstractListModel>
#include <QObject>

#include "atomic.dex.mm2.hpp"

namespace atomic_dex
{
    class transactions_model final : public QAbstractListModel
    {
        Q_OBJECT

        t_transactions m_model_data;

      public:
        enum TransactionsRoles
        {
            AmountRole = Qt::UserRole + 1,
            AmISenderRole,
            DateRole,
            TimestampRole,
            AmountFiatRole,
            TxHashRole,
            FeesRole,
            FromRole,
            ToRole,
            BlockheightRole,
            ConfirmationsRole
        };

        transactions_model(QObject* parent = nullptr) noexcept;
        ~transactions_model() noexcept final;

        //! Override
        [[nodiscard]] QHash<int, QByteArray> roleNames() const final;
        QVariant                             data(const QModelIndex& index, int role) const final;
        int                                  rowCount(const QModelIndex& parent) const final;
    };
} // namespace atomic_dex