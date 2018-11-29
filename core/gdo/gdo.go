package gdo

import (
	"github.com/jmoiron/sqlx"
)

var (
	DB *sqlx.DB
)

func Initialize() error {
	var err error

	DB, err = sqlx.Connect("mysql", "user=foo dbname=bar sslmode=disable")

	if err != nil {
		return err
	}

	return err
}

// Transaction ...
// NOTE: it can also use named return variable for error.
//
// Example:
// err = gdo.Transaction(func(tx *sqlx.Tx) error {
// 	var err error
// 	if _, err = tx.NamedExec("UPDATE tb SET Changed = NOW() WHERE ID = :ID", map[string]interface{}{"ID": 1}); err != nil {
// 		return err
// 	}
// 	return nil
// })

func Transaction(txFunc func(*sqlx.Tx) error) error {
	return *(transaction(DB, txFunc))
}

func TransactionDB(db *sqlx.DB, txFunc func(*sqlx.Tx) error) error {
	return *(transaction(db, txFunc))
}

func transaction(db *sqlx.DB, txFunc func(*sqlx.Tx) error) *error {
	var tx *sqlx.Tx
	err := new(error)

	if tx, *err = db.Beginx(); *err != nil {
		return
	}

	defer func(tx *sqlx.DB, err *error) {
		if tx == nil {
			return
		}

		if p := recover(); p != nil {
			tx.Rollback()

			// re-throw panic after Rollback
			panic(p)
		} else if *err != nil {
			// err is non-nil; don't change it
			tx.Rollback()
		} else {
			// err is nil; if Commit returns error update err
			*err = tx.Commit()
		}
	}(tx, err)

	*err = txFunc(tx)
	return err
}