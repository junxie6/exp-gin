package gdo

import (
	"github.com/jmoiron/sqlx"
)

var (
	DB *sqlx.DB
)

func Initialize() error {
	var err error

	DB, err = sqlx.Connect("mysql", "username:password@protocol(address)/dbname?param=value")

	if err != nil {
		return err
	}

	// TODO: move setting to config
	DB.SetMaxOpenConns(1000)
	DB.SetMaxIdleConns(300)
	DB.SetConnMaxLifetime(0)

	return err
}

// Transaction ...
// NOTE: it can also use named return variable for error.
//
// Example:
// err = gdo.Transaction(func(tx *sqlx.Tx) error {
// 	var err error
//
// 	if _, err = tx.NamedExec("UPDATE tb SET Changed = NOW() WHERE ID = :ID", map[string]interface{}{"ID": 1}); err != nil {
// 		return err
// 	}
//
// 	return nil
// })
func Transaction(txFunc func(*sqlx.Tx) error) error {
	return transaction(DB, txFunc)
}

// TransactionDB ...
func TransactionDB(db *sqlx.DB, txFunc func(*sqlx.Tx) error) error {
	return transaction(db, txFunc)
}

func transaction(db *sqlx.DB, txFunc func(*sqlx.Tx) error) (err error) {
	var tx *sqlx.Tx

	if tx, err = db.Beginx(); err != nil {
		return err
	}

	defer func(tx *sqlx.Tx, e *error) {
		if tx == nil {
			return
		}

		if p := recover(); p != nil {
			tx.Rollback()

			// re-throw panic after Rollback
			panic(p)
		} else if *e != nil {
			// err is non-nil; don't change it
			tx.Rollback()
		} else {
			// err is nil; if Commit returns error update err
			*e = tx.Commit()
		}
	}(tx, &err)

	return txFunc(tx)
}
